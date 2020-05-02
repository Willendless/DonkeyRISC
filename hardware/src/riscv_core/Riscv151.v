`include "defines.vh"
`include "Opcode.vh"
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
    localparam FM_DIM    = 8;
    localparam WT_DIM    = 3;
    localparam AWIDTH    = 14;
    localparam DWIDTH    = 32;
    localparam MEM_DEPTH = 16384;

    localparam WT_OFFSET  = 0;
    localparam IN_OFFSET  = WT_OFFSET + WT_DIM * WT_DIM;
    localparam OUT_OFFSET = IN_OFFSET + FM_DIM * FM_DIM;
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
    wire [31:0] jal_addr;
    wire [1:0] jump_judge;
    wire [31:0] branch_addr;

    wire [`REG_DBUS]    pc_data_reg;
    wire [`REG_DBUS]    pc_plus_reg;
    wire [`WORD_BUS]    alu_result_reg;
    wire branch_judge;
    //wire [31:0] jal_addr1 = jal_addr<<2;
    
    mux_pc mux_pc(
        .pc_plus(pc_plus_reg),
        .jal_addr(jal_addr),//remain some questions
        .branch_addr(branch_addr),
        .jump_judge(jump_judge),
        .branch_judge(branch_judge),
        .pc_o(pc_in));


    wire [31:0] pc_store;

    REGISTER_R #(.N(32), .INIT(RESET_PC-4)) pc_reg(
        .clk(clk),
        .q(pc_store),
        .d(pc_in),
        .rst(rst));

    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    wire [31:0] bios_doutb_judge;

    XILINX_SYNC_RAM_DP #(
        .AWIDTH(BIOS_AWIDTH),
        .DWIDTH(BIOS_DWIDTH),
        .DEPTH(BIOS_DEPTH),
        .MEM_INIT_HEX_FILE(BIOS_MEM_HEX_FILE)
    ) bios_mem(
        .q0(bios_douta),    // output
        .d0(32'b0),              // intput
        .addr0(bios_addra), // input
        .we0(1'b0),         // input
        .q1(bios_doutb_judge),    // output
        .d1(32'b0),              // input
        .addr1(bios_addrb), // input
        .we1(1'b0),         // input
        .clk(clk), .rst(rst));
    
    wire [31:0] alu_result_reg1;
    assign bios_addrb = alu_result_reg1[11:0];

    localparam IMEM_AWIDTH = 14;
    localparam IMEM_DWIDTH = 32;
    localparam IMEM_DEPTH = 16384;

    wire [IMEM_AWIDTH-1:0] imem_addra;
    wire [IMEM_AWIDTH-1:0] imem_addrb;
    wire [IMEM_DWIDTH-1:0] imem_douta;
    wire [IMEM_DWIDTH-1:0] imem_doutb = 32'b0;
    wire [IMEM_DWIDTH-1:0] imem_dina = 32'b0;
    wire [IMEM_DWIDTH-1:0] imem_dinb;
    wire imem_wea = 0;
    wire imem_web;

    wire [3:0] dmem_wea_reg;
    wire [`REG_DBUS]  pc_ex;

    wire [31:0] pc_in1 = pc_in>>2;
    assign imem_addrb = alu_result_reg1[13:0];
    assign imem_addra = pc_in1[IMEM_AWIDTH-1:0];
    assign imem_web = (alu_result_reg[31:29] == 3'b001 && pc_ex[30] == 1'b1)
                       ? (dmem_wea_reg != 4'b0) : 1'b0;
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

    assign bios_addra = pc_in1[BIOS_AWIDTH-1:0];


//-----------second stage----------------//
    wire [31:0] inst_output;

    mux_imem_read mux_imem_read(
        .imem_out(imem_douta),
        .bios_out(bios_douta),
        .pc30(pc_store[30]),
        .inst_output(inst_output));
    
    wire [31:0] imm_out;
    
    wire rf_we;
    wire [4:0]  rf_ra1, rf_ra2, rf_wa;
    wire [31:0] rf_wd;
    wire [31:0] rf_rd1, rf_rd2;

    wire [4:0] wb_addr;
    //assign rf_we = 1'b1;

    wire [`REG_DBUS] reg1_data_reg;
    wire [`REG_ABUS] reg1_addr_reg;
    wire [`REG_DBUS] reg2_data_reg;
    wire [`REG_ABUS] reg2_addr_reg;

    wire inst_alu30_reg;
    wire [2:0] inst_alu_reg;

    wire [1:0] control_forward_reg;
    wire control_dmem_reg;
    wire [1:0] control_jump_reg;    
    wire [1:0] aluOp_reg;
    wire [1:0] control_uart_reg;
    wire [1:0] control_wr_mux_reg;
    wire control_csr_we_reg;

    wire[`REG_ABUS] rd_addr_reg;

    wire [2:0] control_load_reg;
    wire control_branch_reg;
    wire control_wb_reg;
    wire [31:0] branch_addr_reg;
    id ID (
        .inst_i(inst_output),
        .pc_data_i(pc_store),
        .reg1_data_i(rf_rd1),
        .reg2_data_i(rf_rd2),

        .reg1_addr_o(rf_ra1),
        .reg2_addr_o(rf_ra2),
        .funct3_o(inst_alu_reg),
        .inst_alu30_o(inst_alu30_reg),
        .pc_data_o(pc_data_reg),
        .pc_plus_o(pc_plus_reg),
        .imm_o(imm_out),
        .branch_addr_o(branch_addr_reg),    // branch addr
        .rd_addr_o(rd_addr_reg),
        .rs1_addr_o(reg1_addr_reg),
        .rs2_addr_o(reg2_addr_reg),
        .reg1_data_o(reg1_data_reg),
        .reg2_data_o(reg2_data_reg),
        .control_forward_o(control_forward_reg),
        .control_jump_o(control_jump_reg),
        .alu_op_o(aluOp_reg),
        .control_uart_o(control_uart_reg),
        .control_dmem_o(control_dmem_reg),
        .control_wr_mux_o(control_wr_mux_reg),
        .control_csr_we_o(control_csr_we_reg),
        .control_load_o(control_load_reg),
        .control_wb_o(control_wb_reg),
        .control_branch_o(control_branch_reg)
    );

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
    
    wire [31:0] imm_ex;
    wire [31:0] reg1_output;
    wire [31:0] reg2_output;
    wire [4:0] rf1_forward;
    wire [4:0] rf2_forward;
    wire [4:0] wb_addr_ex;

    wire [`REG_DBUS]    pc_plus_ex;

    wire [1:0] control_forward;
    wire [1:0] control_jump;
    wire [1:0] aluOp;
    wire [1:0] control_uart;
    wire control_dmem;
    wire [1:0] control_wr_mux;
    wire control_csr_we;

    wire [2:0] inst_alu;
    wire inst_alu30;

    wire [2:0] control_load_ex;
    wire control_wb_ex;
    wire control_branch;
    wire [31:0] wb_data;

    wire if_flush;
    assign if_flush = rst || branch_judge || jump_judge[0] || jump_judge[1];
    wire control_wb_back;  
    id_ex ID_EX (
        .clk(clk),
        .rst(if_flush),//add jal jalr judge
        .pc_data_i(pc_data_reg),
        .pc_plus_i(pc_plus_reg),
        .reg1_data_i(reg1_data_reg),
        .reg2_data_i(reg2_data_reg),
        .rd_addr_i(rd_addr_reg),
        .reg1_addr_i(reg1_addr_reg),
        .reg2_addr_i(reg2_addr_reg),
        .imm_i(imm_out),
        .funct3_i(inst_alu_reg),
        .inst_alu30_i(inst_alu30_reg),
        .control_forward_i(control_forward_reg),
        .control_jump_i(control_jump_reg),
        .alu_op_i(aluOp_reg),
        .control_uart_i(control_uart_reg),
        .control_dmem_i(control_dmem_reg),
        .control_wr_mux_i(control_wr_mux_reg),
        .control_csr_we_i(control_csr_we_reg),
        .control_load_i(control_load_reg),
        .control_wb_i(control_wb_reg),
        .control_branch_i(control_branch_reg),
        .branch_addr_i(branch_addr_reg),
        .wb_data_i(wb_data),
        .wb_addr_i(wb_addr),
        .is_wb_i(control_wb_back),

        .branch_addr_o(branch_addr),
        .pc_data_o(pc_ex),
        .pc_plus_o(pc_plus_ex),
        .reg1_data_o(reg1_output),
        .reg2_data_o(reg2_output),
        .rd_addr_o(wb_addr_ex),
        .reg1_addr_o(rf1_forward),
        .reg2_addr_o(rf2_forward),
        .imm_o(imm_ex),
        .control_forward_o(control_forward),
        .control_jump_o(control_jump),
        .alu_op_o(aluOp),
        .control_uart_o(control_uart), // TODO
        .control_dmem_o(control_dmem),
        .control_wr_mux_o(control_wr_mux),
        .control_csr_we_o(control_csr_we),
        .funct3_o(inst_alu),
        .inst_alu30_o(inst_alu30),
        .control_load_o(control_load_ex),
        .control_wb_o(control_wb_ex),
        .control_branch_o(control_branch)
    );

    assign jump_judge = control_jump;

//----------------execute stage------------//

    wire [`REG_ABUS]    wb_addr_reg;
    wire [1:0]          control_wr_mux_reg2;
    wire [`REG_DBUS]    pc_plus_reg2;
    wire [`REG_DBUS]    mem_write_reg;   

    wire [3:0]          dmem_wea;

    wire                csr_we;
    wire [`REG_DBUS]    csr_din;
    wire                control_wb;
    wire is_inst_exec;
    wire [1:0] control_uart_wb;

    ex EX (
        .forward_data(wb_data),     // DATA from write back stage
        .pc_data_i(pc_ex),
        .pc_plus_i(pc_plus_ex),
        .reg1_data_i(reg1_output),
        .reg2_data_i(reg2_output),
        .wb_addr_i(wb_addr),
        .rd_addr_i(wb_addr_ex),
        .reg1_addr_i(rf1_forward),
        .reg2_addr_i(rf2_forward),
        .imm_i(imm_ex),
        .funct3_i(inst_alu),
        .inst_alu30_i(inst_alu30),
        .control_forward_i(control_forward),
        .alu_op_i(aluOp),
        .control_uart_i(control_uart),  //TODO
        .control_dmem_i(control_dmem),
        .control_wr_mux_i(control_wr_mux),
        .control_csr_we_i(control_csr_we),
        .control_wb_i(control_wb_ex),
        .control_wb_back(control_wb_back),
        .control_branch_i(control_branch),
        .control_jump_i(control_jump),

        .mem_write_o(mem_write_reg),
        .alu_result_o(alu_result_reg),
        .wb_addr_o(wb_addr_reg),
        .control_wr_mux_o(control_wr_mux_reg2),
        .control_csr_we_o(csr_we),
        .pc_plus_o(pc_plus_reg2),
        .dmem_we(dmem_wea_reg),
        .csr_data_o(csr_din),
        .control_wb_o(control_wb),
        .branch_judge(branch_judge),
        .inst_exec_i(is_inst_exec),
        .control_uart_o(control_uart_wb)
    );

    assign jal_addr = alu_result_reg;

    wire [31:0] rtype_output;
    wire [1:0] control_data;
    wire [31:0] pc_plus_wb;
    wire [2:0] control_load;

    wire [1:0] addr_offset;
    wire [31:0] uart_data_out;

    wire uart_rx_data_out_valid;
    wire uart_tx_data_in_ready;

    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_ready;
    wire [1:0] control_load_uart;

    ex_wb EX_WB (
        .clk(clk),
        .rst(rst),
        .alu_result_i(alu_result_reg),
        .wb_addr_i(wb_addr_reg),
        .control_wr_mux_i(control_wr_mux_reg2),
        .pc_plus_i(pc_plus_reg2),
        .control_load_i(control_load_ex),
        .control_wb_i(control_wb),
        .inst_exec_i(is_inst_exec),
        .uart_rx_out_valid(uart_rx_data_out_valid),
        .uart_tx_in_ready(uart_tx_data_in_ready),
        .uart_read_i(uart_rx_data_out), 
        .control_uart_i(control_uart_wb), 

        .alu_result_o(rtype_output),
        .wb_addr_o(wb_addr),
        .control_wr_mux_o(control_data),
        .pc_plus_o(pc_plus_wb),
        .control_load_o(control_load),
        .addr_offset(addr_offset),
        .control_wb_o(control_wb_back),
        .uart_data_o(uart_data_out),
        .control_uart_o(control_load_uart)
    );
    
    wire uart_tx_data_in_valid;

    assign uart_rx_data_out_ready = (control_uart_wb[0] == 1'b1) && (alu_result_reg == 32'h80000004);
    assign uart_tx_data_in_valid = (control_uart_wb[1] == 1'b1) && (alu_result_reg == 32'h80000008);
   
    // UART Receiver
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
    assign uart_tx_data_in = mem_write_reg[7:0];

    uart_transmitter #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)) uart_tx (
        .clk(clk),
        .rst(rst),
        .data_in(uart_tx_data_in),             // input
        .data_in_valid(uart_tx_data_in_valid), // input
        .data_in_ready(uart_tx_data_in_ready), // output
        .serial_out(FPGA_SERIAL_TX)            // output
    );

    localparam DMEM_AWIDTH = 14;
    localparam DMEM_DWIDTH = 32;
    localparam DMEM_DEPTH = 16384;
    localparam CSR_ADDR = 12'h51e;

    wire [DMEM_AWIDTH-1:0] dmem_addra;
    wire [DMEM_DWIDTH-1:0] dmem_dina, dmem_douta;

    assign imem_dinb = mem_write_reg;
    
    assign alu_result_reg1 = alu_result_reg>>2;

    // Data Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Byte addressable: select which of the four bytes to write
//----------add the conv2d accelerator-------------------//
    reg [31:0] timeout_cycle = 500000;

    // conv controller
    wire idle;
    wire done;
    wire [31:0] fm_dim;
    wire [31:0] wt_offset, ifm_offset, ofm_offset;
    wire conv_start, conv_rst;
    wire [31:0] status_read;
    wire is_conv_addr;

    // channel
    wire [AWIDTH-1:0] req_read_addr;
    wire req_read_addr_valid;
    wire req_read_addr_ready;
    wire [31:0] req_read_len;

    wire [DWIDTH-1:0] resp_read_data;
    wire resp_read_data_valid;
    wire resp_read_data_ready;

    wire [AWIDTH-1:0] req_write_addr;
    wire req_write_addr_valid;
    wire req_write_addr_ready;
    wire [31:0] req_write_len;

    wire [DWIDTH-1:0] req_write_data;
    wire req_write_data_valid;
    wire req_write_data_ready;

    wire resp_write_status;
    wire resp_write_status_valid;
    wire resp_write_status_ready;

    wire [DMEM_AWIDTH-1:0] dmem_addrb;
    wire [3:0] dmem_web;
    wire [DMEM_DWIDTH-1:0] dmem_dinb; //dmem_doutb;

    wire [DMEM_AWIDTH-1:0] dmem_addra_conv, dmem_addrb_conv;
    wire [DMEM_DWIDTH-1:0] dmem_douta_conv, dmem_doutb_conv, dmem_dina_conv, dmem_dinb_conv;
    wire [3:0] dmem_wea_conv, dmem_web_conv;


    conv2D_naive #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .WT_DIM(WT_DIM)
    ) conv2D_naive (
        .clk(clk),
        .rst(rst || conv_rst),

        .start(conv_start),                                // input
        .idle(idle),                                       // output
        .done(done),                                       // output

        .fm_dim(fm_dim),                                   // input
        .wt_offset(wt_offset),                             // input
        .ifm_offset(ifm_offset),                           // input
        .ofm_offset(ofm_offset),                           // input

        // Read Request Address channel
        .req_read_addr(req_read_addr),                     // output
        .req_read_addr_valid(req_read_addr_valid),         // output
        .req_read_addr_ready(req_read_addr_ready),         // input
        .req_read_len(req_read_len),                       // output

        // Read Response channel
        .resp_read_data(resp_read_data),                   // input
        .resp_read_data_valid(resp_read_data_valid),       // input
        .resp_read_data_ready(resp_read_data_ready),       // output

        // Write Request Address channel
        .req_write_addr(req_write_addr),                   // output
        .req_write_addr_valid(req_write_addr_valid),       // output
        .req_write_addr_ready(req_write_addr_ready),       // input
        .req_write_len(req_write_len),                     // output

        // Write Request Data channel
        .req_write_data(req_write_data),                   // output
        .req_write_data_valid(req_write_data_valid),       // output
        .req_write_data_ready(req_write_data_ready),       // input

        // Write Response channel
        .resp_write_status(resp_write_status),             // output
        .resp_write_status_valid(resp_write_status_valid), // output
        .resp_write_status_ready(resp_write_status_ready)  // input
    );

    io_dmem_controller #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .MAX_BURST_LEN(8),
        .IO_LATENCY(10)
    ) io_dmem_controller (
        .clk(clk),
        .rst(rst),

        // Read Request Address channel
        .req_read_addr(req_read_addr),                     // input
        .req_read_addr_valid(req_read_addr_valid),         // input
        .req_read_addr_ready(req_read_addr_ready),         // output
        .req_read_len(req_read_len),                       // input

        // Read Response channel
        .resp_read_data(resp_read_data),                   // output
        .resp_read_data_valid(resp_read_data_valid),       // output
        .resp_read_data_ready(resp_read_data_ready),       // input

        // Write Request Address channel
        .req_write_addr(req_write_addr),                   // input
        .req_write_addr_valid(req_write_addr_valid),       // input
        .req_write_addr_ready(req_write_addr_ready),       // output
        .req_write_len(req_write_len),                     // input

        // Write Request Data channel
        .req_write_data(req_write_data),                   // input
        .req_write_data_valid(req_write_data_valid),       // input
        .req_write_data_ready(req_write_data_ready),       // output

        // Write Response channel
        .resp_write_status(resp_write_status),             // input
        .resp_write_status_valid(resp_write_status_valid), // input
        .resp_write_status_ready(resp_write_status_ready), // output

        // DMem PortA <---> IO Read
        .dmem_douta(dmem_douta_conv), // input
        .dmem_dina(),   // output
        .dmem_addra(dmem_addra_conv), // output
        .dmem_wea(),     // output

        // DMem PortB <---> IO Write
        .dmem_doutb(_), // input
        .dmem_dinb(dmem_dinb_conv),   // output
        .dmem_addrb(dmem_addrb_conv), // output
        .dmem_web(dmem_web)      // output
    );

    // DMem
    XILINX_SYNC_RAM_DP_WBE #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .DEPTH(MEM_DEPTH)
    ) dmem (
        .q0(dmem_douta),
        .d0(dmem_dina),
        .addr0(dmem_addra),
        .wbe0(dmem_wea),

        .q1(),
        .d1(dmem_dinb),
        .addr1(dmem_addrb),
        .wbe1(dmem_web),

        .clk(clk), .rst(rst));
    
    conv_controller conv_reg(
        .rst(rst),
        .clk(clk),

        .cont_data_i(mem_write_reg),
        .cont_addr_i(alu_result_reg),
        .cont_data_o(status_read),

        .conv_idle_i(idle),
        .conv_done_i(done),
        .conv_start_o(conv_start),
        .conv_rst_o(conv_rst),
        .conv_ifm_offset_o(ifm_offset),
        .conv_ofm_offset_o(ofm_offset),
        .conv_fm_dim_o(fm_dim),
        .conv_wt_offset_o(wt_offset),

        .conv_active_o(is_conv_addr)
    );
    //port a is used for read

assign dmem_dina = (alu_result_reg[31:30] == 2'b00 
                    && alu_result_reg[28] == 1'b1) ? mem_write_reg : 
                    32'b0;

assign dmem_addra = (alu_result_reg[31:30] == 2'b00 && alu_result_reg[28] == 1'b1) ?
                    alu_result_reg1[13:0] : 
                    is_conv_addr ? dmem_addra_conv :
                    14'b0;

assign dmem_wea = (alu_result_reg[31:30] == 2'b00 
                    && alu_result_reg[28] == 1'b1) ? dmem_wea_reg : 
                    4'b0;

assign dmem_douta_conv = dmem_douta;

//port b is used for write
assign dmem_web = is_conv_addr ? 4'b1111 : 4'b0;
assign dmem_dinb = is_conv_addr ? dmem_dinb_conv : 32'b0;
assign dmem_addrb = is_conv_addr ? dmem_addrb_conv : 14'b0;
// assign dmem_doutb_conv = dmem_doutb;
//-----------------conv2d-------------------//

    REGISTER_R_CE #(.N(32)) csr_reg (
        .q(csr),
        .d(csr_din),
        .ce(csr_we),
        .clk(clk), .rst(rst)
    );

    assign bios_doutb = (pc_plus_wb[31:28] == 4'b0100 ||
                         rtype_output[31:28] == 4'b0100) ? bios_doutb_judge
                         : 32'b0;  

    //-----------wb stage---------------/
    wb WB (
        .conv_data_i(status_read),
        .uart_data_i(uart_data_out),
        .control_load_i(control_load),
        .control_uart_i(control_load_uart),
        .addr_offset_i(addr_offset),
        .alu_result_i(rtype_output),
        .wb_addr_i(wb_addr),
        .control_wr_mux_i(control_data),
        .pc_plus_i(pc_plus_wb),
        .dmem_douta_i(dmem_douta),
        .bios_doutb_i(bios_doutb),

        .wb_addr_o(rf_wa),
        .wb_data_o(wb_data)              
    );
    assign rf_wd = wb_data;
    assign rf_we = (wb_addr != 32'b0) ? control_wb_back : 1'b0;


    // Construct your datapath, add as many modules as you want

endmodule