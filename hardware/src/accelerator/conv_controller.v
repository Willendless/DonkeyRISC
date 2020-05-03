`include "../riscv_core/defines.vh"
`include "../Opcode.vh"

module conv_controller (
    input rst,
    input clk,
    
    // IO memory map
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

    wire conv_state_next = conv_active_val + 1;
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
    
    assign cont_data_o = (cont_addr_i == `CONV_STATUS) ?
                         {30'b0, idle_val, done_val} : 0;
    
    // scalar signals
    REGISTER_R_CE #(.N(32)) feature_store(
        .q(conv_fm_dim_o),
        .d(cont_data_i),
        .ce(cont_addr_i == `CONV_FM_DIM),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32)) weight_store(
        .q(conv_wt_offset_o),
        .d(cont_data_i),
        .ce(cont_addr_i == `CONV_WEIGHT_OFF),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32)) ofm_store(
        .q(conv_ofm_offset_o),
        .d(cont_data_i),
        .ce(cont_addr_i == `CONV_OUTPUT_FM),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32)) ifm_store(
        .q(conv_ifm_offset_o),
        .d(cont_data_i),
        .ce(cont_addr_i == `CONV_INPUT_FM),
        .rst(rst),
        .clk(clk)
    );

endmodule