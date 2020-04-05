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
    input wire [31:0] forward_data,

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
    output wire[`REG_DBUS]      mem_write_o,      
    output wire[`REG_ABUS]      wb_addr_o,
    output wire[1:0]            control_wr_mux_o,
    output wire[`REG_DBUS]      pc_plus_o,
    output wire [3:0]           dmem_we
    
);
    wire [31:0] aluout;
    assign alu_result_o = aluout;
    dmem_wr dmem_wr (
        .funct3_i(funct3_i),
        .control_dmem(control_dmem_i),
        .addr_offset(aluout[1:0]),
        .dmem_we(dmem_we)
    );

    // write back control signal
    assign wb_addr_o = wb_addr_i;
    assign control_wr_mux_o = control_wr_mux_i;
    // pc
    assign pc_plus_o = pc_plus_i;

    // alu
    wire [3:0] alu_ctrl;

    alu_control alu_control(
        .inst_alu(funct3_i),
        .inst_alu30(inst_alu30_i),
        .aluOp(alu_op_i),
        .aluCtrl(alu_ctrl));
        
    wire [1:0] reg1_judge;
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

    // memory wirte data
    change_mem_wr change_mem_wr(
        .dmem_we(dmem_we),
        .in_data(reg2_data_i),
        .out_data(mem_write_o)
    );
    
    mux_reg1 mux_reg1(
        .wb_data(forward_data),
        .reg1_output(reg1_data_i),
        .reg1_judge(reg1_judge),
        .pc_output(pc_data_i),
        .aluin1(aluin1));
    
    mux_reg2 mux_reg2(
        .wb_data(forward_data),
        .reg2_output(reg2_data_i),
        .imm(imm_i),
        .reg2_judge(reg2_judge),
        .aluin2(aluin2));

    alu alu(
        .aluin1(aluin1),
        .aluin2(aluin2),
        .aluCtrl(alu_ctrl),
        .aluout(aluout));
    
    wire 
    jb_unit jb_unit(
        .control_jump(control_jump_i),
        .branch_comp_result(branch_comp_result),
        .jump_judge(jump_judge),
        .if_flush(if_flush)
    );

endmodule // ex 