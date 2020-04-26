`include "../riscv_core/defines.vh"
`include "../Opcode.vh"
module reg_offset (
    input [31:0] mem_write_i,
    input [31:0] conv_addr_i,
    input rst,
    input clk,
    input idle_i,
    input done_i,

    output [31:0] ifm_offset_o,
    output [31:0] ofm_offset_o,
    output [31:0] fm_dim_o,
    output [31:0] wt_offset_o,
    output start_o,
    output [31:0] status_read_o
);

wire feature_ce = (conv_addr_i == `CONV_FEATURE);
wire weight_ce = (conv_addr_i == `CONV_WEIGHT);
wire input_ce = (conv_addr_i == `CONV_INPUT);
wire output_ce = (conv_addr_i == `CONV_OUTPUT);
wire status_ce = (conv_addr_i == `CONV_READ);

wire status_i = {30'b0, idle_i, done_i};

REGISTER_R_CE #(.N(32)) feature_store(
    .q(fm_dim_o),
    .d(mem_write_i),
    .ce(feature_ce),
    .rst(rst),
    .clk(clk)
);

REGISTER_R_CE #(.N(32)) weight_store(
    .q(wt_offset_o),
    .d(mem_write_i),
    .ce(weight_ce),
    .rst(rst),
    .clk(clk)
);

REGISTER_R_CE #(.N(32)) ofm_store(
    .q(ofm_offset_o),
    .d(mem_write_i),
    .ce(output_ce),
    .rst(rst),
    .clk(clk)
);

REGISTER_R_CE #(.N(32)) ifm_store(
    .q(ifm_offset_o),
    .d(mem_write_i),
    .ce(input_ce),
    .rst(rst),
    .clk(clk)
);

assign start_o = (conv_addr_i == `CONV_WRITE);

REGISTER_R_CE #(.N(32)) status_store(
    .q(status_read_o),
    .d(status_i),
    .rst(rst),
    .ce(status_ce),
    .clk(clK)
);

endmodule