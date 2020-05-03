`include "../defines.vh"
`include "../Opcode.vh"

module conv_controller (
    input rst,
    input clk,
    
    // IO memory map
    input [3:0] conv_we_i,
    input [`WORD_BUS] cont_data_i,
    input [`WORD_BUS] cont_addr_i,
    output[`WORD_BUS] cont_data_o,

    output conv_active_o,

    // Interact with conv2D
    
    // Control/Status signals
    input conv_idle_i,
    input conv_done_i,
    output conv_start_o,
    output conv_rst_o,
    // Scalar signals
    output [31:0] conv_ifm_offset_o,
    output [31:0] conv_ofm_offset_o,
    output [31:0] conv_fm_dim_o,
    output [31:0] conv_wt_offset_o
);

    // control/status signals

    assign conv_rst_o = (cont_addr_i == `CONV_RESET);
    assign conv_start_o = (cont_addr_i == `CONV_START);

    wire conv_active_val;
    assign conv_active_o = conv_active_val;

    wire conv_state_next = ~conv_active_val;
    wire conv_state_ce = ((cont_addr_i == `CONV_START) && conv_idle_i) || conv_done_i;
    REGISTER_R_CE #(.N(1), .INIT(0)) conv_state_reg(
        .q(conv_active_val),
        .d(conv_state_next),
        .ce(conv_state_ce),
        .clk(clk),
        .rst(rst)
    );

    wire idle_val;
    REGISTER_R #(.N(1)) idle_reg(
        .q(idle_val),
        .d(conv_idle_i),
        .rst(rst),
        .clk(clk)
    );
    wire done_val;
    REGISTER_R #(.N(1)) done_reg(
        .q(done_val),
        .d(conv_done_i),
        .rst(rst),
        .clk(clk)
    );

    wire [31:0] cont_read = {30'b0, idle_val, done_val};

    REGISTER_R #(.N(32)) reg_start(
        .q(cont_data_o),
        .d(cont_read),
        .clk(clk),
        .rst(rst)
    );

    wire [31:0] conv_data_we;
    change_mem_wr change_conv(
    .dmem_we(conv_we_i),
    .in_data(cont_data_i),
    .out_data(conv_data_we)
    );
    // scalar signals
    REGISTER_R_CE #(.N(32)) feature_store(
        .q(conv_fm_dim_o),
        .d({16'b0, conv_data_we[15:0]}),
        .ce((cont_addr_i == `CONV_FM_DIM) && (conv_we_i > 4'b0)),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32)) weight_store(
        .q(conv_wt_offset_o),
        .d({16'b0, conv_data_we[15:0]}),
        .ce((cont_addr_i == `CONV_WEIGHT_OFF) && (conv_we_i > 4'b0)),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32)) ofm_store(
        .q(conv_ofm_offset_o),
        .d({16'b0, conv_data_we[15:0]}),
        .ce((cont_addr_i == `CONV_OUTPUT_FM) && (conv_we_i > 4'b0)),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32)) ifm_store(
        .q(conv_ifm_offset_o),
        .d({16'b0, conv_data_we[15:0]}),
        .ce((cont_addr_i == `CONV_INPUT_FM) && (conv_we_i > 4'b0)),
        .rst(rst),
        .clk(clk)
    );

endmodule