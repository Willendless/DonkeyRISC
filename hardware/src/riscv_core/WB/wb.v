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
    output wire[`REG_DBUS]      wb_data_o
);
    assign wb_addr_o = wb_addr_i;
    wire [31:0] dmem_load_i;
    wire [31:0] bios_load_i;
    wire [31:0] wb_data; 
    wire [31:0] before_uart_data;


    mux_dmem mux_dmem(
        .dmem_output(dmem_load_i),
        .bios_output(bios_load_i),
        .pc_output(pc_plus_i),
        .rtype_output(alu_result_i),
        .control_data(control_wr_mux_i),
        .addr(alu_result_i[31:28]),
        .wb_data(before_uart_data));
    
    assign wb_data = (control_uart_i > 2'b0 
                      && (alu_result_i == 32'h80000000 || alu_result_i == 32'h80000004
                      ||  alu_result_i == 32'h80000010 || alu_result_i == 32'h80000014))
                      ? uart_data_i :
                      (control_uart_i == 2'b01 && (alu_result_i == `CONV_WRITE))
                      ? conv_data_i :
                      before_uart_data;

    assign wb_data_o = (wb_addr_i == 32'b0) ? 31'b0 : wb_data;
    
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