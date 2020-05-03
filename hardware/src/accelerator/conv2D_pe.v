// basic 1D convolution processing element
module conv2D_pe #(
    parameter AWIDTH = 32,
    parameter DWIDTH = 32,
    parameter WT_DIM = 3
) (
    input clk,
    input rst,

    // Control signals
    input state_i, // TODO

    //Current OFM(y, x)
    input [DWIDTH-1:0] x,
    input [DWIDTH-1:0] y,

    input                   load_weights_en, // TODO
    input [DWIDTH-1:0]      index_i,
    input [DWIDTH-1:0]      pe_data_i,

    input               read_data_valid,

    //control signal
    // input               pe_in_fire,     // data from ifm

    // result to fifo
    output[DWIDTH-1:0]  pe_data_o,
    output              pe_data_valid
);

    localparam WT_SIZE      = WT_DIM * WT_DIM;
    localparam HALF_WT_DIM  = WT_DIM >> 1;

    wire halo              = x == 0 | y == 0 | x == WT_DIM + 1 | y == WT_DIM + 1;

    wire [DWIDTH-1:0] index;
    REGISTER_R #(.N(DWIDTH)) index_reg (
        .q(index),
        .d(index_i),
        .clk(clk),
        .rst(rst));

    // weight registers
    wire [DWIDTH-1:0] weight_reg_q[WT_DIM-1:0];
    wire weight_reg_en[WT_DIM-1:0];

    genvar i;
    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin:in
            assign weight_reg_en[i] = read_data_valid && load_weights_en
                                      && y == index && x == i; // TODO
            REGISTER_R_CE #(.N(DWIDTH), .INIT(32'b0)) weight_reg (
                .q(weight_reg_q[i]),
                .d(pe_data_i),
                .ce(weight_reg_en[i]),
                .clk(clk),
                .rst(rst));
        end
    endgenerate

    // shift data into registers
    wire [DWIDTH-1:0] inputs_reg_q[WT_DIM-1:0];
    wire [DWIDTH-1:0] inputs_reg_d[WT_DIM:0];
    wire inputs_reg_en[WT_DIM-1:0];

    assign inputs_reg_d[0] = (halo == 1'b1) ? 32'b0 : pe_data_i;
    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin
            assign inputs_reg_d[i+1] = inputs_reg_q[i];
            assign inputs_reg_en[i] = read_data_valid && index >= y;   // TODO
            REGISTER_R_CE #(.N(DWIDTH), .INIT(32'b0)) input_reg (
                .q(inputs_reg_q[i]),
                .d(inputs_reg_d[i]),
                .ce(inputs_reg_ce),
                .clk(clk),
                .rst(rst));
        end
    endgenerate

    wire [DWIDTH-1:0] mult_result[WT_DIM-1:0];
    generate
        for (i = 0; i < WT_DIM; i = i + 1) begin
            assign mult_result[i] = inputs_reg_q[i] * weight_reg_q[i];
        end
    endgenerate

    integer j;
    reg [DWIDTH-1:0] sum_val;
    always @(*) begin
        sum_val = 32'b0;
        for (j = 0; j < WT_DIM; j = j + 1) begin
            sum_val = sum_val + mult_result[j];
        end
    end

    wire [DWIDTH-1:0] counter_d;
    wire [DWIDTH-1:0] counter_q;
    wire counter_ce;
    REGISTER_R_CE #(.N(DWIDTH), .INIT(32'b0)) counter (
        .q(counter_q),
        .d(counter_d),
        .ce(counter_ce),
        .clk(clk),
        .rst(rst)
    );

    assign counter_d    = counter_q + 1;
    assign counter_ce   = state_i == && counter_q < WT_DIM; // TODO

    assign pe_data_o    = sum_val;
    assign pe_data_valid  = ~counter_ce; 

endmodule // conv_pe
