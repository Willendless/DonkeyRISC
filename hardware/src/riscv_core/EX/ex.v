/**
* execution stage
*   @OUTPUT:
*   
* 
*
*/
`include "../defines.vh"
`include "../Opcode.vh"
module ex (
    //  forward data
    input wire [31:0] forward_data,
    input wire[`REG_ABUS]   wb_addr_i,

    // pc & pc+4
    input wire[`REG_DBUS]      pc_data_i,
    input wire[`REG_DBUS]      pc_plus_i,

    //
    input wire[`REG_DBUS]   reg1_data_i,
    input wire[`REG_DBUS]   reg2_data_i,
    input wire[`REG_ABUS]   rd_addr_i,
    input wire[`REG_ABUS]   reg1_addr_i,
    input wire[`REG_ABUS]   reg2_addr_i,
    input wire[`IMM32_BUS]    imm_i,
    input wire[3:0]         alu_ctrl_i,

    input wire[2:0]     funct3_i,
    input wire if_flush_i,

    // control signal
    input wire[1:0] control_forward_i,
    input wire [1:0] control_uart_i, //TODO
    input wire control_dmem_i,
    input wire[1:0] control_wr_mux_i,
    input wire control_csr_we_i,
    input wire control_wb_i,
    input wire control_wb_back,
    input wire control_branch_i,
    input wire[1:0] control_jump_i,

    output wire[`WORD_BUS]      alu_result_o,
    output wire[`REG_DBUS]      mem_write_o,      
    output wire[`REG_ABUS]      wb_addr_o,
    output wire[1:0]            control_wr_mux_o,
    output wire[`REG_DBUS]      pc_plus_o,
    output wire [3:0]           dmem_we,
    output wire                 control_csr_we_o,
    output wire[`REG_DBUS]      csr_data_o,
    output wire                 control_wb_o,

    output wire                 inst_exec_i,
    output wire [1:0]           control_uart_o,
    output wire                 is_load_o,
    output wire [31:0]          alu_addr_result_o,
    output wire [31:0]          wb_alu_data_o

);
    assign is_load_o = (control_wr_mux_i == 2'b10);

    wire [31:0] alu_addr_result;
    wire [31:0] aluout;
    assign alu_addr_result_o = alu_addr_result;

    
    wire is_uart_data = alu_addr_result == 32'h80000004 || alu_addr_result == 32'h80000008
                            || alu_addr_result == 32'h80000000 || alu_addr_result == 32'h80000010 
                            || alu_addr_result == 32'h80000014;
    assign control_uart_o = (is_uart_data || alu_addr_result == `CONV_READ) ?
                            control_uart_i : 2'b0;
    
    assign alu_result_o = aluout;
    dmem_wr dmem_wr (
        .funct3_i(funct3_i),
        .control_dmem(control_dmem_i),
        .addr_offset(alu_addr_result[1:0]),
        .dmem_we(dmem_we)
    );



    // write back control signal
    assign wb_addr_o = rd_addr_i;
    assign control_wr_mux_o = control_wr_mux_i;
    // pc
    assign pc_plus_o = pc_plus_i;

    // alu
    wire [3:0] alu_ctrl;
        
    wire [1:0]  reg1_judge;
    wire [1:0]  reg2_judge;

    mux_alu_wb mux_alu_ex(
    .pc_output(pc_plus_i),
    .rtype_output(aluout),
    .control_data(control_wr_mux_i),
    .wb_alu_data(wb_alu_data_o)
);


    forwarding_unit forwarding_unit(
        .reg1_addr(reg1_addr_i),
        .reg2_addr(reg2_addr_i),
        .wb_addr(wb_addr_i),
        .is_wb(control_wb_back),
        .control_forward(control_forward_i),
        .reg1_judge(reg1_judge),
        .reg2_judge(reg2_judge),
        .mem_wdata_judge(mem_wdata_judge));

    assign control_wb_o = control_wb_i;
    
    wire [31:0] aluin1;
    wire [31:0] aluin2;

    wire [`REG_DBUS]    mem_wdata;
    assign mem_wdata = mem_wdata_judge == 1'b0 ? reg2_data_i : forward_data;

    // csr control signal
    assign control_csr_we_o = control_csr_we_i;
    assign csr_data_o = funct3_i == 3'b001 ? aluin1 : 
                        funct3_i == 3'b101 ? imm_i : 32'b0;

    // memory wirte data
    change_mem_wr change_mem_wr(
        .dmem_we(dmem_we),
        .in_data(mem_wdata),
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
        .aluCtrl(alu_ctrl_i),
        .alu_addr_out(alu_addr_result),
        .aluout(aluout));
    
    wire [31:0] branch_comp_a;
    wire [31:0] branch_comp_b;

    assign inst_exec_i = ~if_flush_i;
    

endmodule // ex 