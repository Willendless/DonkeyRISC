`include "../defines.vh"
`include "../mux.v"

module wb (
    // from ex_wb
    input wire[3:0]             alu_result_i,
    input wire[1:0]             wb_addr_i,
    input wire[1:0]             control_wr_mux_i,
    input wire[1:0]             pc_plus_i,

    //from mem
    input wire[`DMEM_DBUS]      dmem_douta_i,
    input wire[`BIOS_DBUS]      bios_doutb_i,          
    output wire[`REG_ABUS]      wb_addr_o,
    output wire[`REG_DBUS]      wb_data_o
);
    assign wb_addr_o = wb_addr_i;

    mux_dmem mux_dmem(
        .dmem_output(dmem_douta_i),
        .bios_output(bios_doutb_i),
        .pc_output(pc_plus_i),
        .rtype_output(alu_result_i),
        .control_data(control_wr_mux_i),
        .addr(alu_result_i[31:28]),
        .wb_data(wb_data_o));

endmodule