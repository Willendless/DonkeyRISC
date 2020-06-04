
`include "../defines.vh"
`include "../Opcode.vh"
module wb (
    // from ex_wb
    input wire[31:0]             conv_data_i,
    input wire[31:0]             alu_result_i,
    input wire[4:0]              wb_addr_i,
    input wire[1:0]              control_wr_mux_i,
    input wire[31:0]             pc_plus_i,
    input wire[2:0]              control_load_i,
    input wire[1:0]              addr_offset_i,
    input wire[31:0]             uart_data_i,
    input wire[1:0]              control_uart_i,

    //from mem
    input wire[`DMEM_DBUS]      dmem_douta_i,
    input wire[`BIOS_DBUS]      bios_doutb_i,          
    output wire[`REG_ABUS]      wb_addr_o,
    output wire[`REG_DBUS]      wb_data_o,
    output wire[`REG_DBUS]      wb_alu_data_o,
    output wire                 is_load_o
);
    assign wb_addr_o = wb_addr_i;
    wire [31:0] dmem_load_i;
    wire [31:0] bios_load_i;

    wire [31:0] wb_dmem_data;

    mux_dmem mux_dmem(
        .dmem_output(dmem_load_i),
        .bios_output(bios_load_i),
        .conv_data_i(conv_data_i),
        .uart_data_i(uart_data_i),
        .control_data(control_wr_mux_i),
        .addr(alu_result_i),
        .control_uart_i(control_uart_i),
        .wb_dmem_data(wb_dmem_data));

    wire [31:0] wb_alu_data;
    mux_alu_wb mux_alu_wb(
        .pc_output(pc_plus_i),
        .rtype_output(alu_result_i),
        .control_data(control_wr_mux_i),
        .wb_alu_data(wb_alu_data)
    );

    wire [31:0] wb_data_ori;
    assign wb_data_ori = (control_wr_mux_i == 2'b10) ? wb_dmem_data : wb_alu_data;
    assign wb_data_o = (wb_addr_i == 32'b0) ? 32'b0 : wb_data_ori;
    assign wb_alu_data_o = wb_alu_data;
    assign is_load_o = (control_wr_mux_i == 2'b10);
    
    load_type dmem_load_type(
        .addr_offset(addr_offset_i),
        .control_load(control_load_i),
        .dmem_load_i(dmem_douta_i),
        .dmem_data_o(dmem_load_i));
    load_type bios_load_type(
        .addr_offset(addr_offset_i),
        .control_load(control_load_i),
        .dmem_load_i(bios_doutb_i),
        .dmem_data_o(bios_load_i));

endmodule