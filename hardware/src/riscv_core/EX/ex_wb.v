`include "../defines.vh"
`include "../Opcode.vh"
module ex_wb (
    input clk,
    input rst,
    input wire[`WORD_BUS]       alu_result_i,
    input wire[`REG_ABUS]       wb_addr_i,
    input wire[1:0]             control_wr_mux_i,
    input wire[`REG_DBUS]       pc_plus_i,
    input wire[2:0]             control_load_i,
    input wire                  control_wb_i,
    input wire                  inst_exec_i,
    input wire                  uart_rx_out_valid,
    input wire                  uart_tx_in_ready,
    input [7:0]                 uart_read_i, 
    input [1:0]                 control_uart_i,

    output wire[2:0]            control_load_o,
    output wire[`WORD_BUS]      alu_result_o,
    output wire[`REG_ABUS]      wb_addr_o,
    output wire[1:0]            control_wr_mux_o,
    output wire[`REG_DBUS]      pc_plus_o,
    output wire[1:0]            addr_offset,
    output wire                 control_wb_o,
    output [31:0]               uart_data_o,
    output wire[1:0]            control_uart_o
);
    REGISTER_R #(.N(2)) store_uart(
        .q(control_uart_o),
        .clk(clk),
        .rst(rst),
        .d(control_uart_i));

    REGISTER_R #(.N(3)) store_load(
        .q(control_load_o),
        .clk(clk),
        .rst(rst),
        .d(control_load_i));
    
    REGISTER_R #(.N(2)) store_offset(
        .q(addr_offset),
        .clk(clk),
        .rst(rst),
        .d(alu_result_i[1:0]));

    REGISTER_R #(.N(32)) store_alu(
        .q(alu_result_o),
        .clk(clk),
        .rst(rst),
        .d(alu_result_i));

    REGISTER_R #(.N(5)) store_addr(
        .q(wb_addr_o),
        .clk(clk),
        .rst(rst),
        .d(wb_addr_i));
    
    REGISTER_R #(.N(2)) store_control(
        .q(control_wr_mux_o),
        .clk(clk),
        .rst(rst),
        .d(control_wr_mux_i));
    
    REGISTER_R # (.N(32)) store_pc_wb(
        .q(pc_plus_o),
        .clk(clk),
        .rst(rst),
        .d(pc_plus_i));
    
    REGISTER_R # (.N(1)) store_control_wb(
        .q(control_wb_o),
        .clk(clk),
        .rst(rst),
        .d(control_wb_i));
    /*
    wire [7:0] store_data;
    REGISTER_R_CE # (.N(8), .INIT(7'b0)) store_uart_data(
        .q(store_data),
        .d(uart_read_i),
        .clk(clk),
        .rst(rst),
        .ce(uart_rx_out_valid)
    );*/
    
    wire [31:0] cycle_count1;
    wire [31:0] cycle_count2;
    wire reset_count;
    wire is_count;

    assign reset_count = (alu_result_i == 32'h80000018) || rst;

    assign is_count = inst_exec_i;

    REGISTER_R # (.N(32), .INIT(32'b0)) cycle_counter(
        .q(cycle_count1),
        .d(cycle_count2),
        .rst(reset_count),
        .clk(clk)
    );

    assign cycle_count2 = cycle_count1 + 1;

    wire [31:0] inst_count1;
    wire [31:0] inst_count2;
    assign inst_count2 = inst_count1 + 1;

    REGISTER_R_CE # (.N(32), .INIT(32'b0)) inst_counter(
        .q(inst_count1),
        .d(inst_count2),
        .rst(reset_count),
        .clk(clk),
        .ce(is_count)
    );

    reg [31:0] uart_data;

always @(*) begin
    case(alu_result_i)
        32'h80000000: uart_data = {30'b0, uart_rx_out_valid, uart_tx_in_ready};
        32'h80000004: uart_data = {24'b0, uart_read_i};
        32'h80000010: uart_data = cycle_count1;
        32'h80000014: uart_data = inst_count1;
        default: uart_data = 32'b0;
    endcase
end

    REGISTER_R #(.N(32), .INIT(32'b0)) uart_lw(
        .clk(clk),
        .rst(rst),
        .q(uart_data_o),
        .d(uart_data)
    );
endmodule