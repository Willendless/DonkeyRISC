// basic 1D convolution processing element
module conv2D_pe #(
    parameter AWIDTH = 32,
    parameter DWIDTH = 32,
    parameter WT_DIM = 3
) (
    input clk,
    input rst,

    input [DWIDTH-1:0]      index_i,
    input [DWIDTH-1:0]      fm_dim,

    input [DWIDTH-1:0]      pe_weight_data_i,
    input                   pe_weight_data_valid,
    input [DWIDTH-1:0]      pe_fm_data_i,
    input                   pe_fm_data_valid,

    // result to fifo
    output [DWIDTH-1:0]     pe_data_o,
    output                  pe_data_valid
);

    localparam halo_cnt  = (WT_DIM - 1);
    localparam half_halo_cnt = halo_cnt >> 1;
    wire [31:0] x_cnt_edge = (fm_dim + halo_cnt - 1);
    wire [31:0] y_cnt_edge = (fm_dim + halo_cnt - 1);

    localparam WT_SIZE      = WT_DIM * WT_DIM;

    wire halo;

    wire [DWIDTH-1:0] index;
    REGISTER_R #(.N(DWIDTH)) index_reg (
        .q(index),
        .d(index_i),
        .clk(clk),
        .rst(rst));

    // m index register: 0 ---> WT_DIM - 1
    wire [31:0] m_cnt_d, m_cnt_q;
    wire m_cnt_ce, m_cnt_rst;
    REGISTER_R_CE #(.N(32), .INIT(0)) m_cnt_reg (
        .q(m_cnt_q),
        .d(m_cnt_d),
        .ce(m_cnt_ce),
        .rst(m_cnt_rst),
        .clk(clk)
    );
    // n index register: 0 ---> WT_DIM -1
    wire [31:0] n_cnt_d, n_cnt_q;
    wire n_cnt_ce, n_cnt_rst;
    REGISTER_R_CE #(.N(32), .INIT(0)) n_cnt_reg (
        .q(n_cnt_q),
        .d(n_cnt_d),
        .ce(n_cnt_ce),
        .rst(n_cnt_rst),
        .clk(clk)
    );
    assign n_cnt_d      = n_cnt_q + 1;
    assign n_cnt_ce     = pe_weight_data_valid;
    assign n_cnt_rst    = (n_cnt_q == WT_DIM - 1 & pe_weight_data_valid) | rst; 

    assign m_cnt_d      = m_cnt_q + 1;
    assign m_cnt_ce     = (pe_weight_data_valid && n_cnt_q == WT_DIM - 1);
    assign m_cnt_rst    = (n_cnt_q == WT_DIM - 1 & m_cnt_q == WT_DIM -1 & pe_weight_data_valid) | rst;

    // weight registers
    wire [DWIDTH-1:0] weight_reg_q[WT_DIM-1:0];
    wire [DWIDTH-1:0] weight_reg_d[WT_DIM-1:0];
    wire weight_reg_en[WT_DIM-1:0];

    genvar i;
    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin:weight
            REGISTER_R_CE #(.N(DWIDTH), .INIT(32'b0)) weight_reg (
                .q(weight_reg_q[i]),
                .d(weight_reg_d[i]),
                .ce(weight_reg_en[i]),
                .clk(clk),
                .rst(rst));
        end
    endgenerate

    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin
            assign weight_reg_d[i] = pe_weight_data_i;
            assign weight_reg_en[i] =  m_cnt_q == index_i
                                        & n_cnt_q == i & pe_weight_data_valid;
        end
    endgenerate


    // x index register: 0 -----> fm_dim + 1 
    wire [DWIDTH-1:0] x_cnt_reg_d, x_cnt_reg_q;
    wire x_cnt_reg_ce, x_cnt_reg_rst;
    REGISTER_R_CE #(.N(DWIDTH), .INIT(0)) x_cnt_reg (
        .q(x_cnt_reg_q),
        .d(x_cnt_reg_d),
        .ce(x_cnt_reg_ce),
        .rst(x_cnt_reg_rst),
        .clk(clk)
    );

    // y index register: 0 -----> fm_dim + 1
    wire [DWIDTH-1:0] y_cnt_reg_d, y_cnt_reg_q;
    wire y_cnt_reg_ce, y_cnt_reg_rst;
    REGISTER_R_CE #(.N(DWIDTH), .INIT(0)) y_cnt_reg (
        .q(y_cnt_reg_q),
        .d(y_cnt_reg_d),
        .ce(y_cnt_reg_ce),
        .rst(y_cnt_reg_rst),
        .clk(clk)
    );

    wire weight_done_q, weight_done_d;
    wire weight_done_ce, weight_done_rst;
    REGISTER_R_CE #(.N(1), .INIT(0)) weight_done_reg (
        .q(weight_done_q),
        .d(weight_done_d),
        .ce(weight_done_ce),
        .rst(weight_done_rst),
        .clk(clk)
    );

    assign x_cnt_reg_d      = x_cnt_reg_q + 1;
    assign x_cnt_reg_ce     = weight_done_q & (pe_fm_data_valid | halo);
    assign x_cnt_reg_rst    = (x_cnt_reg_q == x_cnt_edge) & (pe_fm_data_valid | halo);

    assign y_cnt_reg_d      = y_cnt_reg_q + 1;
    assign y_cnt_reg_ce     = weight_done_q & (x_cnt_reg_q == x_cnt_edge)
                                            & (pe_fm_data_valid | halo);
    assign y_cnt_reg_rst    = weight_done_q & (x_cnt_reg_q == x_cnt_edge)
                                            & (y_cnt_reg_q == y_cnt_edge)
                                            & (pe_fm_data_valid | halo);

    assign halo         = (x_cnt_reg_q < half_halo_cnt) | (y_cnt_reg_q < half_halo_cnt)
                                                    | (x_cnt_reg_q > (x_cnt_edge - half_halo_cnt))
                                                    | (y_cnt_reg_q > (y_cnt_edge - half_halo_cnt));

    assign weight_done_d    = ~weight_done_q;
    assign weight_done_ce   = (m_cnt_q == WT_DIM - 1) & (n_cnt_q == WT_DIM - 1) & pe_weight_data_valid;
    assign weight_done_rst  = y_cnt_reg_rst; // all feature map data went into feature map registers

    // feature map data registers
    wire [DWIDTH-1:0] inputs_reg_q[WT_DIM-1:0];
    wire [DWIDTH-1:0] inputs_reg_d[WT_DIM-1:0];
    wire inputs_reg_en[WT_DIM-1:0];
    wire inputs_reg_rst[WT_DIM-1:0];

    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin:fm
            REGISTER_R_CE #(.N(DWIDTH), .INIT(32'b0)) input_reg (
                .q(inputs_reg_q[i]),
                .d(inputs_reg_d[i]),
                .ce(inputs_reg_en[i]),
                .clk(clk),
                .rst(inputs_reg_rst[i]));
        end
    endgenerate

    wire pe_out_fire_d, pe_out_fire_q;
    wire pe_out_fire_rst, pe_out_fire_en;
    REGISTER_R_CE #(.N(1), .INIT(0)) pe_out_fire (
        .q(pe_out_fire_q),
        .d(pe_out_fire_d),
        .ce(pe_out_fire_en),
        .rst(pe_out_fire_rst),
        .clk(clk)
    );

    assign pe_out_fire_d    = 1'b1;
    assign pe_out_fire_en   = weight_done_q & (y_cnt_reg_q >= index_i & x_cnt_reg_q >= WT_DIM - 1)
                                & (pe_fm_data_valid | halo);
    assign pe_out_fire_rst  = ~weight_done_q | rst | (y_cnt_reg_q < index_i | x_cnt_reg_q < WT_DIM - 1);

    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin
            if (i == 0) begin
                assign inputs_reg_d[i]      = (halo == 1'b1) ? 32'b0 : pe_fm_data_i;
                assign inputs_reg_en[i]     = y_cnt_reg_q >= index_i & (pe_fm_data_valid | halo == 1'b1);
                assign inputs_reg_rst[i]    =  ~weight_done_q | rst; 
            end else begin
                assign inputs_reg_d[i]      = inputs_reg_q[i - 1];
                assign inputs_reg_en[i]     = weight_done_q;
                assign inputs_reg_rst[i]    = ((x_cnt_reg_q == WT_DIM + 1 & pe_fm_data_valid) & ~weight_done_q) | rst;
            end
        end
    endgenerate

    wire [DWIDTH-1:0] mult_result[WT_DIM-1:0];
    wire [DWIDTH-1:0] result_store[WT_DIM-1:0];
    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin
            assign mult_result[i] = inputs_reg_q[i] * weight_reg_q[WT_DIM - 1 - i];
            REGISTER_R #(.N(32)) result_store (
                .q(result_store[i]),
                .d(mult_result[i]),
                .clk(clk),
                .rst(rst)
            );
        end
    endgenerate

    integer j;
    reg [DWIDTH-1:0] sum_val;
    always @(*) begin
        sum_val = 32'b0;
        for (j = 0; j < WT_DIM; j = j + 1) begin
            sum_val = sum_val + result_store[j];
        end
    end

    wire pe_fire;
    REGISTER_R #(.N(1)) pe_fire_reg (
        .q(pe_fire),
        .d(pe_out_fire_q),
        .clk(clk),
        .rst(rst)
    );

    assign pe_data_o        = sum_val;
    assign pe_data_valid    = pe_fire; 

endmodule // conv_pe
