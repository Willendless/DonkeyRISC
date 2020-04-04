`include "alu.v"
`include "../EECS151.v"
`include "mux.v"
`include "alu_control.v"
`include "control_unit.v"
`include "forwarding_unit.v"
`include "imm_gen.v"
`include "jump_unit.v"

module Riscv151
#(
    parameter CPU_CLOCK_FREQ    = 50_000_000,
    parameter RESET_PC          = 32'h4000_0000,
    parameter BAUD_RATE         = 115200,
    parameter BIOS_MEM_HEX_FILE = "bios151v3.mif"
)
(
    input  clk,
    input  rst,
    input  FPGA_SERIAL_RX,
    output FPGA_SERIAL_TX,
    output [31:0] csr
);


/*
    parameter CPU_CLOCK_FREQ    = 50_000_000;
    parameter RESET_PC          = 32'h4000_0000;
    parameter BAUD_RATE         = 115200;
    parameter BIOS_MEM_HEX_FILE = "bios151v3.mif";*/
    // Memories
    //-----------first stage----------------//
    localparam BIOS_AWIDTH = 12;
    localparam BIOS_DWIDTH  = 32;
    localparam BIOS_DEPTH  = 4096;

    wire [BIOS_AWIDTH-1:0] bios_addra, bios_addrb;
    wire [BIOS_DWIDTH-1:0] bios_douta, bios_doutb;

    wire [31:0] pc_in;
    wire [31:0] pc_plus;
    wire [31:0] jal_addr;
    wire jump_judge;

    mux_pc mux_pc(
        .pc_plus(pc_plus),
        .jal_addr(jal_addr),
        .jump_judge(jump_judge),
        .pc_in(pc_in));

    wire [31:0] pc_store;
    wire [31:0] pc_output;

    REGISTER #(.N(32)) pc_reg(
        .clk(clk),
        .q(pc_store),
        .d(pc_in));

    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    XILINX_SYNC_RAM_DP #(
        .AWIDTH(BIOS_AWIDTH),
        .DWIDTH(BIOS_DWIDTH),
        .DEPTH(BIOS_DEPTH),
        .MEM_INIT_HEX_FILE(BIOS_MEM_HEX_FILE)
    ) bios_mem(
        .q0(bios_douta),    // output
        .d0(),              // intput
        .addr0(bios_addra), // input
        .we0(1'b0),         // input
        .q1(bios_doutb),    // output
        .d1(),              // input
        .addr1(bios_addrb), // input
        .we1(1'b0),         // input
        .clk(clk), .rst(rst));

    localparam IMEM_AWIDTH = 14;
    localparam IMEM_DWIDTH = 32;
    localparam IMEM_DEPTH = 16384;

    wire [IMEM_AWIDTH-1:0] imem_addra, imem_addrb;
    wire [IMEM_DWIDTH-1:0] imem_douta, imem_doutb;
    wire [IMEM_DWIDTH-1:0] imem_dina, imem_dinb;
    wire [3:0] imem_wea, imem_web;

    // Instruction Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Byte addressable: select which of the four bytes to write
    XILINX_SYNC_RAM_DP #(
        .AWIDTH(IMEM_AWIDTH),
        .DWIDTH(IMEM_DWIDTH),
        .DEPTH(IMEM_DEPTH)
    ) imem (
        .q0(imem_douta),    // output
        .d0(imem_dina),     // input
        .addr0(imem_addra), // input
        .we0(imem_wea),    // input
        .q1(imem_doutb),    // output
        .d1(imem_dinb),     // input
        .addr1(imem_addrb), // input
        .we1(imem_web),    // input
        .clk(clk), .rst(rst));

    assign bios_addra = pc_in[11:0];
    assign imem_addra = pc_in[13:0];
    assign pc_store = pc_in;
    
    wire if_flush = jump_judge;

//-----------second stage----------------//
    wire [31:0] inst_output;

    mux_imem_read mux_imem_read(
        .imem_out(imem_douta),
        .bios_out(bios_douta),
        .pc30(1),
        .inst_output(inst_output));
    
    wire [31:0] imm_out;
    
    imm_gen imm_gen(
        .inst_origin(inst_output),
        .imm(imm_out));
    
    wire rf_we;
    wire [4:0]  rf_ra1, rf_ra2, rf_wa;
    wire [31:0] rf_wd;
    wire [31:0] rf_rd1, rf_rd2;
    // Asynchronous read: read data is available in the same cycle
    // Synchronous write: write takes one cycle
    REGFILE_1W2R # (
        .AWIDTH(5),
        .DWIDTH(32),
        .DEPTH(32)
    ) rf (
        .d0(rf_wd),     // input
        .addr0(rf_wa), // input
        .we0(rf_we),    // input
        .q1(rf_rd1),    // output
        .addr1(rf_ra1), // input
        .q2(rf_rd2),    // output
        .addr2(rf_ra2), // input
        .clk(clk));
    
    wire [4:0] wb_addr;
    assign rf_ra1 = inst_output[19:15];
    assign rf_ra2 = inst_output[24:20];
    assign rf_wa = wb_addr;
    assign rf_we = 1'b1;
    
    wire [31:0] imm_ex;

    REGISTER_R #(.N(32)) imm_shift(
        .q(imm_ex),
        .d(imm_out),
        .clk(clk),
        .rst(if_flush));

    wire [31:0] reg1_output;

    REGISTER_R #(.N(32)) reg1_store(
        .clk(clk),
        .rst(if_flush),
        .q(reg1_output),
        .d(rf_rd1));
    
    wire [31:0] reg2_output;

    REGISTER_R #(.N(32)) reg2_store(
        .clk(clk),
        .rst(if_flush),
        .q(reg2_output),
        .d(rf_rd2));

    wire [6:0] inst_control;

    REGISTER_R #(.N(7)) reg_inst_store(
        .clk(clk),
        .rst(if_flush),
        .q(inst_control),
        .d(inst_output[6:0]));
    
    wire [4:0] rf1_forward;
    wire [4:0] rf2_forward;

    REGISTER_R #(.N(5)) reg1_addr_store(
        .clk(clk),
        .rst(if_flush),
        .q(rf1_forward),
        .d(rf_ra1));
    REGISTER_R #(.N(5)) reg2_addr_store(
        .clk(clk),
        .rst(if_flush),
        .q(rf2_forward),
        .d(rf_ra2));

    wire [4:0] wb_addr_ex;
    REGISTER_R #(.N(5)) reg0_addr_store(
        .clk(clk),
        .rst(if_flush),
        .d(inst_output[11:7]),
        .q(wb_addr_ex));
    
    assign pc_output = pc_store + 4;
    assign pc_plus = pc_output;

    wire [31:0] pc_plus_ex;
    REGISTER_R #(.N(32)) store_pc_plus(
        .clk(clk),
        .rst(if_flush),
        .q(pc_plus_ex),
        .d(pc_output));
    
    wire [31:0] pc_ex;
    REGISTER_R #(.N(32)) store_pc(
        .clk(clk),
        .rst(if_flush),
        .q(pc_ex),
        .d(pc_store));

    wire control_forward_reg;
    wire control_dmem_reg;
    wire [1:0] control_jump_reg;
    wire [1:0] aluOp_reg;
    wire control_uart_reg;
    wire [1:0] control_wr_mux_reg;

    control_unit control_unit(
        .inst(inst_output),
        .control_forward(control_forward_reg),
        .control_dmem(control_dmem_reg),
        .control_jump(control_jum_reg),
        .control_uart(control_uart_reg),
        .aluCtrl(aluCtrl_reg),
        .control_wr_mux(control_wr_mux_reg));

    wire control_forward;
    wire [1:0] control_jump;
    wire [1:0] aluOp;
    wire control_uart;
    wire control_dmem;
    wire [1:0] control_wr_mux;

    REGISTER_R #(.N(1)) forward_reg(
        .clk(clk),
        .rst(if_flush),
        .q(control_forward),
        .d(control_forward_reg));
    
    REGISTER_R #(.N(2)) alu_reg(
        .clk(clk),
        .rst(if_flush),
        .q(aluOp),
        .d(aluOp_reg));
    
    REGISTER_R #(.N(2)) jump_reg(
        .clk(clk),
        .rst(if_flush),
        .q(control_jump),
        .d(control_jump_reg));
    
    REGISTER_R #(.N(1)) uart_reg(
        .clk(clk),
        .rst(if_flush),
        .q(control_uart),
        .d(control_uart_reg));
    
    REGISTER_R #(.N(1)) dmem_reg(
        .clk(clk),
        .rst(if_flush),
        .q(control_dmem),
        .d(control_dmem_reg));

    REGISTER_R #(.N(2)) wr_mux_reg(
        .clk(clk),
        .rst(if_flush),
        .q(control_wr_mux),
        .d(control_wr_mux_reg));
    
    wire [2:0] inst_alu;
    wire inst_alu30;

    REGISTER_R #(.N(4)) inst_alu_reg(
        .clk(clk),
        .rst(if_flush),
        .q({inst_alu, inst)alu30}),
        .d({inst_output[14:12], inst_output}));


//----------------execute stage------------//

    alu_control alu_control(
        .inst_alu(inst_alu),
        .inst_alu30(inst_alu30),
        .aluOp(aluOp),
        .aluCtrl(aluCtrl));
        
    wire reg1_judge;
    wire [1:0] reg2_judge;

    forwarding_unit forwarding_unit(
        .reg1_addr(rf1_forward),
        .reg2_addr(rf2_forward),
        .wb_addr(wb_addr),
        .control_forward(control_forward),
        .reg1_judge(reg1_judge),
        .reg2_judge(reg2_judge));

    wire [31:0] aluin1;
    wire [31:0] aluin2;
    wire [31:0] wb_data;
    
    mux_reg1 mux_reg1(
        .wb_data(wb_data),
        .reg1_output(reg1_output),
        .reg1_judge(reg1_judge),
        .aluin1(aluin1));
    
    mux_reg2 mux_reg2(
        .wb_data(wb_data),
        .reg2_output(reg1_output),
        .imm(imm_ex),
        .reg2_judge(reg2_judge),
        .aluin2(aluin2));

    wire aluout;
    wire branch_judge;

    alu alu(
        .aluin1(aluin1),
        .aluin2(aluin2),
        .aluCtrl(aluCtrl),
        .aluout(aluout),
        .branch_judge(branch_judge));
    
    jump_unit jump_unit(
        .control_jump(control_jump),
        .branch_judge(branch_judge),
        .jump_judge(jump_judge));
    
    wire [31:0] rtype_output;

    REGISTER #(.N(32)) store_alu(
        .q(rtype_output),
        .clk(clk),
        .d(aluout));

    REGISTER #(.N(5)) store_addr(
        .q(wb_addr),
        .clk(clk),
        .d(wb_addr_ex));
    
    wire [1:0] control_data;
    
    REGISTER #(.N(32)) store_control(
        .q(control_data),
        .clk(clk),
        .d(control_wr_mux));
    
    wire [31:0] pc_plus_wb;

    REGISTER # (.N(32)) store_pc_wb(
        .q(pc_plus_wb),
        .clk(clk),
        .d(pc_plus_ex));

    assign jal_addr = pc_ex + imm_ex;

    
    //-----------wb stage---------------/
    // UART Receiver
    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    wire uart_rx_data_out_ready;

    localparam DMEM_AWIDTH = 32;
    localparam DMEM_DWIDTH = 32;
    localparam DMEM_DEPTH = 16384;

    wire [DMEM_AWIDTH-1:0] dmem_addra;
    wire [DMEM_DWIDTH-1:0] dmem_dina, dmem_douta;
    wire [3:0] dmem_wea;

    assign dmem_wea = control_dmem;
    assign dmem_dina = aluin2;

    // Data Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Byte addressable: select which of the four bytes to write
    SYNC_RAM_WBE #(
        .AWIDTH(DMEM_AWIDTH),
        .DWIDTH(DMEM_DWIDTH),
        .DEPTH(DMEM_DEPTH)
    ) dmem (
        .q(dmem_douta),    // output
        .d(dmem_dina),     // input
        .addr(dmem_addra), // input
        .wbe(dmem_wea),    // input
        .clk(clk), .rst(rst));

    assign dmem_addra = aluout;
    assign imem_addrb = aluout;
    assign bios_addrb = aluout;

    mux_dmem(
        .dmem_output(dmem_douta),
        .bios_output(bios_doutb),
        .pc_output(pc_plus_wb),
        .rtype_output(rtype_output),
        .control_data(control_data),
        .addr(rtype_output[31:28]),
        .wb_data(wb_data));

    assign rf_wd = wb_data;

/*
    uart_receiver #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)) uart_rx (
        .clk(clk),
        .rst(rst),
        .data_out(uart_rx_data_out),             // output
        .data_out_valid(uart_rx_data_out_valid), // output
        .data_out_ready(uart_rx_data_out_ready), // input
        .serial_in(FPGA_SERIAL_RX)               // input
    );

    // UART Transmitter
    wire [7:0] uart_tx_data_in;
    wire uart_tx_data_in_valid;
    wire uart_tx_data_in_ready;

    uart_transmitter #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)) uart_tx (
        .clk(clk),
        .rst(reset),
        .data_in(uart_tx_data_in),             // input
        .data_in_valid(uart_tx_data_in_valid), // input
        .data_in_ready(uart_tx_data_in_ready), // output
        .serial_out(FPGA_SERIAL_TX)            // output
    );

*/
    // Construct your datapath, add as many modules as you want

endmodule