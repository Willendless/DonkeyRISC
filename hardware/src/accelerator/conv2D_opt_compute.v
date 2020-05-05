`include "conv2D_pe.v"

module conv2D_opt_compute #(
    parameter AWIDTH = 32,
    parameter DWIDTH = 32,
    parameter WT_DIM = 3
) (
    input clk,
    input rst,

    // Control/status signals
    input start,
    output idle,

    // // Current OFM(y, x)
    // input [31:0] x,
    // input [31:0] y,

    // Feature map dimension
    input [31:0] fm_dim,

    // Read data from mem_opt_if
    input [DWIDTH-1:0]  rdata,
    input               rdata_valid,
    output              rdata_ready,

    // Write data to mem_opt_if
    input               wdata_ready,
    output [DWIDTH-1:0] wdata,
    output              wdata_valid 
);




    // data from io_mem
    fifo #(.WIDTH(DWIDTH), .LOGDEPTH(10)) data_in_fifo(
        .clk(clk),
        .rst(rst)
    );

    // data to io_mem
    fifo data_out_fifo();


    localparam STATE_IDLE       = 2'b00;
    localparam STATE_READ_WT    = 2'b01;
    localparam STATE_COMPUTE    = 2'b10;
    localparam STATE_DONE       = 2'b11;

    // state register
    wire [1:0] state_q;
    reg  [1:0] state_d;

    REGISTER_R #(.N(2), .INIT(STATE_IDLE)) state_reg (
        .q(state_q),
        .d(state_d),
        .rst(rst),
        .clk(clk)
    );

   // m index register: 0 --> WT_DIM - 1
    wire [31:0] m_cnt_d, m_cnt_q;
    wire m_cnt_ce, m_cnt_rst;

    REGISTER_R_CE #(.N(32), .INIT(0)) m_cnt_reg (
        .q(m_cnt_q),
        .d(m_cnt_d),
        .ce(m_cnt_ce),
        .rst(m_cnt_rst),
        .clk(clk)
    );

    wire [31:0] n_cnt_d, n_cnt_q;
    wire n_cnt_ce, n_cnt_rst;

    REGISTER_R_CE #(.N(32), .INIT(0)) n_cnt_reg (
        .q(n_cnt_q),
        .d(n_cnt_d),
        .ce(n_cnt_ce),
        .rst(n_cnt_rst),
        .clk(clk)
    );

    // 0----->fm_dim+1
    wire [31:0] x_cnt_d, x_cnt_q;
    wire x_cnt_ce, x_cnt_rst;
    REGISTER_R_CE #(.N(32), .INIT(0)) x_cnt_reg (
        .q(x_cnt_q),
        .d(x_cnt_d),
        .ce(x_cnt_ce),
        .rst(x_cnt_rst),
        .clk(clk)
    );

    // 0------>fm_dim+1
    wire [31:0] y_cnt_d, y_cnt_q;
    wire y_cnt_ce, y_cnt_rst;
    REGISTER_R_CE #(.N(32), .INIT(0)) y_cnt_reg (
        .q(y_cnt_q),
        .d(y_cnt_d),
        .ce(y_cnt_ce),
        .rst(y_cnt_rst),
        .clk(clk)
    );

    wire [31:0] wt_idx = m_cnt_q * WT_DIM + n_cnt_q;
    wire [31:0] ifm_idx = (y_cnt_q - 1) * fm_dim + (x_cnt_q - 1);








    wire rdata_fire = rdata_valid & rdata_ready;
    wire wdata_fire = wdata_valid & wdata_ready;
    wire halo       = x_cnt_q <= 0 | x_cnt_q > fm_dim | y_cnt_q <= 0 | y_cnt_q > fm_dim;

    assign rdata_ready = (state_q == STATE_READ_WT) || (state_q == STATE_COMPUTE && ~halo);

    always @(*) begin
        state_d = state_q;
        case (state_q)
            STATE_IDLE: begin
                if (start)
                    state_d = STATE_READ_WT;
            end
            // Load WT_DIM x WT_DIM weight elements from DMem
            STATE_READ_WT: begin
                if (x_cnt_q == WT_DIM - 1 & y_cnt_q == WT_DIM - 1 & rdata_fire)
                    state_d = STATE_COMPUTE;
            end
            // One sliding window computation
            STATE_COMPUTE: begin
                if ()
                    state_d = STATE_DONE;
            end
            // produce one ofm
            STATE_DONE: begin
                if (x_cnt_q == fm_dim - 1 & y_cnt_q == fm_dim -1)
                    state_d = STATE_IDLE;
                else
                    state_d = STATE_COMPUTE;
            end
        endcase
    end

    // Generate instances of PE
    wire [DWIDTH-1:0] pe_data_outputs[WT_DIM-1:0];
    wire pe_data_valids[WT_DIM-1:0];
    wire pe_rst;
    genvar i;
    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin:PE
            conv2D_pe #(.AWIDTH(AWIDTH),
                        .DWIDTH(DWIDTH),
                        .WT_DIM(WT_DIM)) pe (
                            .clk(clk),
                            .rst(pe_rst),
                            .state_i(state_q),
                            .x(x_cnt_q),
                            .y(y_cnt_q),
                            .index_i(i),
                            .pe_data_i(rdata),
                            .read_data_valid(rdata_valid),
                            .pe_data_o(pe_data_outputs[i]),
                            .pe_data_valid(pe_data_valids[i]));
        end
    endgenerate

    assign pe_rst = (state_q == STATE_DONE) | rst;

    // Generate fifo for each pe
    // LOGDEPTH: 2^5 = 32
    // enq
    wire pe_fifo_enq_ready = (state_q == STATE_COMPUTE) || (state_q == STATE_READ_WT);
    // deq
    reg pe_fifo_deq_ready;
    wire pe_fifo_deq_valids[WT_DIM-1:0];
    wire [DWIDTH-1:0] pe_fifo_deq_datas[WT_DIM-1:0];

    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin:FIFO
            fifo #(.WIDTH(32), .LOGDEPTH(5)) fifo (
                .clk(clk),
                .rst(rst),
                .enq_valid(pe_data_valids[i]),
                .enq_data(pe_data_outputs[i]),
                .enq_ready(pe_fifo_enq_ready),
                .deq_valid(pe_fifo_deq_valids[i]),
                .deq_data(pe_fifo_deq_datas[i]),
                .deq_ready(pe_fifo_enq_ready));
        end
    endgenerate

    // independent logic to calculate ofm
    // fifo deq ready
    integer j;
    always @(*) begin
        pe_fifo_deq_ready = 1'b0;
        for (j = 0; j < WT_DIM - 1; j = j + 1) begin
            pe_fifo_deq_ready = pe_fifo_deq_ready & pe_fifo_deq_valids[j]; 
        end
        pe_fifo_deq_ready = pe_fifo_deq_ready & (state_q == STATE_COMPUTE);
    end


    wire ofm_fire = pe_fifo_deq_ready;

    integer k;
    reg [DWIDTH-1:0] ofm;
    always @(*) begin
        ofm = 32'b0;
        for (k = 0; k < WT_DIM - 1; k = k + 1) begin
            ofm = ofm + pe_fifo_deq_datas[k];
        end
    end

    assign wdata_valid = ofm_fire;
endmodule // conv2D_opt_compute