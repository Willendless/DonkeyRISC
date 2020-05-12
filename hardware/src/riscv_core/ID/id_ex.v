
`include "../defines.vh"
`include "../Opcode.vh"
/*
*   TODO:
*   id_ex pipeline register file, connect to ex stage
*   @OUTPUT:
*   wb_addr
*   imm
*   alu_op*
*   //control signal*
*   reg1_data
*   reg2_data
*   //write_back enable*
*   
    output wire[`REG_ABUS]      wb_addr_o,
    output wire[`REG_ABUS]      rs1_addr_o,
    output wire[`REG_ABUS]      rs2_addr_o,
    output wire[`REG_DBUS]      reg1_data_o,
    output wire[`REG_DBUS]      reg2_data_o,

    output reg [1:0] control_forward_o,
    output [1:0] control_jump_o,
    output [1:0] alu_op_o,
    output control_uart_o, //TODO
    output control_dmem_o,
    output [1:0] control_wr_mux_o
*/
module id_ex (
    input wire rst,
    input wire clk,
    input wire flush_i,

    input wire[`REG_DBUS]      pc_data_i,
    input wire[`REG_DBUS]      pc_plus_i,
    output wire[`REG_DBUS]      pc_data_o,
    output wire[`REG_DBUS]      pc_plus_o,

    input wire[`REG_DBUS]   reg1_data_i,
    input wire[`REG_DBUS]   reg2_data_i,
    input wire[`REG_ABUS]   rd_addr_i,
    input wire[`REG_ABUS]   reg1_addr_i,
    input wire[`REG_ABUS]   reg2_addr_i,
    input wire[`IMM32_BUS]    imm_i,

    output wire[`REG_DBUS]   reg1_data_o,
    output wire[`REG_DBUS]   reg2_data_o,
    output wire[`REG_ABUS]   rd_addr_o,
    output wire[`REG_ABUS]   reg1_addr_o,
    output wire[`REG_ABUS]   reg2_addr_o,
    output wire[`IMM32_BUS]    imm_o,

    input wire[2:0]     funct3_i,

    // control signal
    input wire[1:0] control_forward_i,
    input wire[1:0] control_jump_i,
    input wire [1:0] control_uart_i, //TODO
    input wire control_dmem_i,
    input wire[1:0] control_wr_mux_i,
    input wire control_csr_we_i,
    input wire [2:0] control_load_i,
    input wire control_wb_i,
    input wire control_branch_i,
    input [31:0] branch_addr_i,
    input [31:0] wb_data_i,
    input [4:0] wb_addr_i,
    input is_wb_i,
    input [3:0] alu_ctrl_i,

    input [4:0] wb_hazard_addr_i,
    input wire [31:0] forward_data_i,

    output [3:0] alu_ctrl_o,
    output [1:0] control_forward_o,
    output [1:0] control_jump_o,
    output [1:0] control_uart_o, //TODO
    output control_dmem_o,
    output [1:0] control_wr_mux_o,
    output wire control_csr_we_o,
    output wire [2:0] control_load_o,
    output wire control_wb_o,
    output wire control_branch_o,
    output [31:0] branch_addr_o,

    output wire is_load_hazard_o,

    output wire[2:0]  funct3_o

    // input wire              alu_src1_sel_i,
    // input wire              alu_src2_sel_i,
    // input wire              mem_read_i,
    // input wire              mem_write_i,
    // input wire              wb_enable_i,
    // //input wire pc_sel

    // output wire             alu_src1_sel_o,
    // output wire             alu_src2_sel_o,
    // output wire             mem_read_o,
    // output wire             mem_write_o,
    // output wire             wb_enable_o
    //output pc_sel

);
    wire is_flush = flush_i || rst;

    REGISTER_R #(.N(1)) control_wb_reg ( 
        .clk(clk),
        .rst(is_flush),
        .q(control_wb_o),
        .d(control_wb_i));
    // pc & pc + 4
    REGISTER_R #(.N(`REG_DWIDTH)) pc_data_reg ( 
        .clk(clk),
        .rst(rst),
        .q(pc_data_o),
        .d(pc_data_i));
    REGISTER_R #(.N(`REG_DWIDTH)) pc_plus_reg ( 
        .clk(clk),
        .rst(rst),
        .q(pc_plus_o),
        .d(pc_plus_i));


    // reg data & addr
    wire [31:0] reg1_data_o1;
    REGISTER_R #(.N(`REG_DWIDTH)) reg1_store(
        .clk(clk),
        .rst(is_flush),
        .q(reg1_data_o),
        .d(reg1_data_o1));

    assign reg1_data_o1 = ((reg1_addr_i == wb_hazard_addr_i) && is_wb_i)
                         ? wb_data_i : reg1_data_i;
    
    wire [31:0] reg2_data_o1;
    REGISTER_R #(.N(`REG_DWIDTH)) reg2_store(
        .clk(clk),
        .rst(is_flush),
        .q(reg2_data_o),
        .d(reg2_data_o1));
    assign reg2_data_o1 = (reg2_addr_i == wb_hazard_addr_i && is_wb_i)
                         ? wb_data_i : reg2_data_i;
    
    REGISTER_R #(.N(`REG_AWIDTH)) reg1_addr_store(
        .q(reg1_addr_o),
        .clk(clk),
        .rst(is_flush),
        .d(reg1_addr_i));

    REGISTER_R #(.N(`REG_AWIDTH)) reg2_addr_store(
        .q(reg2_addr_o),
        .clk(clk),
        .rst(is_flush),
        .d(reg2_addr_i));

    REGISTER_R #(.N(`REG_AWIDTH)) rd_addr_store (
        .q(rd_addr_o),
        .clk(clk),
        .rst(is_flush),
        .d(rd_addr_i));

    REGISTER_R #(.N(`IMM32_WIDTH)) imm_data (
        .q(imm_o),
        .clk(clk),
        .rst(is_flush),
        .d(imm_i)
    );

    REGISTER_R #(.N(1)) load_sign (
        .q(control_dmem_o),
        .clk(clk),
        .rst(is_flush),
        .d(control_dmem_i)
    );


//    output wire[2:0]         funct3_o,
//    output wire              inst_alu30_o,     
    REGISTER_R #(.N(3)) funct3_reg (
        .clk(clk),
        .rst(is_flush),
        .d(funct3_i),
        .q(funct3_o));

    // control data
    REGISTER_R #(.N(2)) forward_reg(
        .clk(clk),
        .rst(is_flush),
        .q(control_forward_o),
        .d(control_forward_i));
    
    REGISTER_R #(.N(4)) alu_ctrl_reg(
        .clk(clk),
        .rst(is_flush),
        .q(alu_ctrl_o),
        .d(alu_ctrl_i));
    
    assign is_load_hazard_o = ((reg1_addr_i == wb_addr_i) ||
                              (reg2_addr_i == wb_addr_i)) &&
                              (wb_addr_i !== 32'b0);

    REGISTER_R #(.N(2), .INIT(2'b0)) jump_reg(
        .clk(clk),
        .rst(is_flush),
        .q(control_jump_o),
        .d(control_jump_i));
    
    REGISTER_R #(.N(2)) uart_reg(
        .clk(clk),
        .rst(is_flush),
        .q(control_uart_o),
        .d(control_uart_i));
    
    REGISTER_R #(.N(1)) dmem_reg(
        .clk(clk),
        .rst(is_flush),
        .q(control_dmem_o),
        .d(control_dmem_i));

    REGISTER_R #(.N(2)) wr_mux_reg(
        .clk(clk),
        .rst(is_flush),
        .q(control_wr_mux_o),
        .d(control_wr_mux_i));

    REGISTER_R #(.N(1)) csr_we_reg(
        .clk(clk),
        .rst(is_flush),
        .q(control_csr_we_o),
        .d(control_csr_we_i));
    
    REGISTER_R #(.N(1)) ctrl_branch_reg(
        .clk(clk),
        .rst(is_flush),
        .q(control_branch_o),
        .d(control_branch_i));
    
    REGISTER_R #(.N(3)) control_load(
        .clk(clk),
        .rst(is_flush),
        .q(control_load_o),
        .d(control_load_i)
    );

    REGISTER_R #(.N(32)) branch_addr_load(
        .clk(clk),
        .rst(rst),
        .q(branch_addr_o),
        .d(branch_addr_i)
    );




endmodule // id_ex