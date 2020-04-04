/**
* execution stage
*   @OUTPUT:
*   
* 
*
*/
`include "../defines.vh"
`include "../mux.v"

module ex (
    //  write_back data
    input wire [31:0] wb_data,

    // pc & pc+4
    input wire[`REG_DBUS]      pc_data_i,
    input wire[`REG_DBUS]      pc_plus_i,

    //
    input wire[`REG_DBUS]   reg1_data_i,
    input wire[`REG_DBUS]   reg2_data_i,
    input wire[`REG_ABUS]   wb_addr_i,
    input wire[`REG_ABUS]   reg1_addr_i,
    input wire[`REG_ABUS]   reg2_addr_i,
    input wire[`IMM32_BUS]    imm_i,

    input wire[2:0]     funct3_i,
    input wire          inst_alu30_i,

    // control signal
    input wire[1:0] control_forward_i,
    input wire[1:0] control_jump_i,
    input wire[1:0] alu_op_i,
    input wire control_uart_i, //TODO
    input wire control_dmem_i,
    input wire[1:0] control_wr_mux_i,


    output wire[`WORD_BUS]      alu_result_o,
    output wire[`REG_ABUS]      wb_addr_o,
    output wire[1:0] control_wr_mux_o,
    output wire[`REG_DBUS]      pc_plus_o
    
);

    // pc
    assign pc_plus_o = pc_plus_i;

    // alu
    wire [3:0] alu_ctrl;

    alu_control alu_control(
        .inst_alu(funct3_i),
        .inst_alu30(inst_alu30_i),
        .aluOp(alu_op_i),
        .aluCtrl(alu_ctrl));
        
    wire reg1_judge;
    wire [1:0] reg2_judge;

    forwarding_unit forwarding_unit(
        .reg1_addr(reg1_addr_i),
        .reg2_addr(reg2_addr_i),
        .wb_addr(wb_addr_i),
        .control_forward(control_forward_i),
        .reg1_judge(reg1_judge),
        .reg2_judge(reg2_judge));

    wire [31:0] aluin1;
    wire [31:0] aluin2;
    
    mux_reg1 mux_reg1(
        .wb_data(wb_data),
        .reg1_output(reg1_data_i),
        .reg1_judge(reg1_judge),
        .aluin1(aluin1));
    
    mux_reg2 mux_reg2(
        .wb_data(wb_data),
        .reg2_output(reg2_data_i),
        .imm(imm_ex),
        .reg2_judge(reg2_judge),
        .aluin2(aluin2));

    alu alu(
        .aluin1(aluin1),
        .aluin2(aluin2),
        .aluCtrl(alu_ctrl),
        .aluout(alu_result_o));

endmodule // ex 