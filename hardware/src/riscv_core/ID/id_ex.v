`include "../defines.vh"

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
    input wire          inst_alu30_i,

    // control signal
    input wire[1:0] control_forward_i,
    input wire[1:0] control_jump_i,
    input wire[1:0] alu_op_i,
    input wire control_uart_i, //TODO
    input wire control_dmem_i,
    input wire[1:0] control_wr_mux_i,

    output reg[1:0] control_forward_o,
    output [1:0] control_jump_o,
    output [1:0] alu_op_o,
    output control_uart_o, //TODO
    output control_dmem_o,
    output [1:0] control_wr_mux_o,

    output wire[2:0]         funct3_o,
    output wire              inst_alu30_o

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
    REGISTER_R #(.N(`REG_DWIDTH)) reg1_store(
        .clk(clk),
        .rst(rst),
        .q(reg1_data_i),
        .d(reg1_data_o));

    REGISTER_R #(.N(`REG_DWIDTH)) reg2_store(
        .clk(clk),
        .rst(rst),
        .q(reg2_data_i),
        .d(reg2_data_o));

    REGISTER_R #(.N(`REG_AWIDTH)) reg1_addr_store(
        .q(reg1_addr_o),
        .clk(clk),
        .rst(rst),
        .d(reg1_addr_i));

    REGISTER_R #(.N(`REG_AWIDTH)) reg2_addr_store(
        .q(reg2_addr_o),
        .clk(clk),
        .rst(rst),
        .d(reg2_addr_i));

    REGISTER_R #(.N(`REG_AWIDTH)) rd_addr_store (
        .q(rd_addr_i),
        .clk(clk),
        .rst(rst),
        .d(rd_addr_o));

    REGISTER_R #(.N(`IMM32_WIDTH)) imm_data (
        .q(imm_o),
        .clk(clk),
        .rst(rst),
        .d(imm_i)
    );


//    output wire[2:0]         funct3_o,
//    output wire              inst_alu30_o,     
    REGISTER_R #(.N(3)) funct3_reg (
        .clk(clk),
        .rst(rst),
        .d(funct3_i),
        .q(funct3_o));
    
    REGISTER_R #(.N(1)) inst_alu30_reg (
        .clk(clk),
        .rst(rst),
        .d(inst_alu30_i),
        .q(inst_alu30_o));

    // control data
    REGISTER_R #(.N(2)) forward_reg(
        .clk(clk),
        .rst(rst),
        .q(control_forward_o),
        .d(control_forward_i));
    
    REGISTER_R #(.N(2)) alu_reg(
        .clk(clk),
        .rst(rst),
        .q(alu_op_o),
        .d(alu_op_i));
    
    REGISTER_R #(.N(2)) jump_reg(
        .clk(clk),
        .rst(rst),
        .q(control_jump_o),
        .d(control_jump_i));
    
    REGISTER_R #(.N(1)) uart_reg(
        .clk(clk),
        .rst(rst),
        .q(control_uart_o),
        .d(control_uart_i));
    
    REGISTER_R #(.N(1)) dmem_reg(
        .clk(clk),
        .rst(rst),
        .q(control_dmem_o),
        .d(control_dmem_i));

    REGISTER_R #(.N(2)) wr_mux_reg(
        .clk(clk),
        .rst(rst),
        .q(control_wr_mux_o),
        .d(control_wr_mux_i));


    // // mux signal
    // wire mux_signals_next [0:5];
    // wire mux_signals_val  [0:5];
    // assign  mux_signals_next[0] = alu_src1_sel_i,
    //         mux_signals_next[1] = alu_src2_sel_i,
    //         mux_signals_next[2] = mem_read_i,
    //         mux_signals_next[3] = mem_write_i,
    //         mux_signals_next[4] = wb_enable_i;
    // //TODO: pc_sel
    // assign  alu_src1_sel_o  = mux_signals_val[0],
    //         alu_src2_sel_o  = mux_signals_val[1],
    //         mem_read_o      = mux_signals_val[2],
    //         mem_write_o     = mux_signals_val[3],
    //         wb_enable_o     = mux_signals_val[4];

    // generate
    //     for (i = 0; i < 5; i = i + 1) begin
    //        REGISTER_R #(.N(1)) mux_sel (
    //            .q(mux_signals_val[i]),
    //            .clk(clk),
    //            .rst(rst),
    //            .d(mux_signals_next[i])
    //        ); 
    //     end
    // endgenerate


endmodule // id_ex