`ifndef MUX
`define MUX
`include "../defines.vh"
`include "../Opcode.vh"
module mux_dmem(
    input [31:0] dmem_output,
    input [31:0] bios_output,
    input [31:0] conv_data_i,
    input [31:0] uart_data_i,

    input [1:0] control_data,
    input [31:0] addr,
    input [1:0] control_uart_i,
    output [31:0] wb_dmem_data
);
//writeback mux
assign wb_dmem_data = (control_data == 2'b10 && (addr[31:28] == 4'b0001 || addr[31:28] == 4'b0011)) ? dmem_output://choose the result of dmem
                 (control_data == 2'b10 && addr[31:28] == 4'b0100) ? bios_output://choose bios memory
                 (control_uart_i > 2'b0 && (addr == 32'h80000000 || addr == 32'h80000004
                 ||  addr == 32'h80000010 || addr == 32'h80000014))
                 ? uart_data_i : (control_uart_i == 2'b01 && (addr == `CONV_READ))
                 ? conv_data_i :
                 32'b0;
endmodule

module mux_alu_wb(
    input [31:0] pc_output,
    input [31:0] rtype_output,
    input [1:0] control_data,
    output [31:0] wb_alu_data
);

assign wb_alu_data = (control_data == 2'b01) ? rtype_output:
                     (control_data == 2'b11) ? pc_output:
                     32'b0;
endmodule



module mux_pc(
    input [31:0] pc_plus,
    input [31:0] pc_data,
    input [31:0] jal_addr,
    input [31:0] branch_addr,
    input [1:0] jump_judge,
    input branch_judge,
    input is_load_hazard_i,

    output [31:0] pc_o
);
//define the input of jump signal
assign pc_o = (is_load_hazard_i == 1'b1) ? pc_data :
              (jump_judge > 0) ? jal_addr :
              (jump_judge == 0 && branch_judge == 1) ? branch_addr :
              pc_plus;

endmodule

module mux_reg1(
    input [31:0] wb_data,
    input [31:0] reg1_output,
    input [31:0] pc_output,
    input [1:0] reg1_judge,
    output [31:0] aluin1
);

assign aluin1 = (reg1_judge == `REG1_MUX_REG) ? reg1_output :
                (reg1_judge == `REG1_MUX_WB) ? wb_data : 
                (reg1_judge == `REG1_MUX_PC) ? pc_output : 
                32'b0;
endmodule

module mux_reg2(
    input [31:0] imm,
    input [31:0] reg2_output,
    input [31:0] wb_data,
    input [1:0] reg2_judge,
    output [31:0] aluin2
);

assign aluin2 = (reg2_judge == `REG2_MUX_REG) ? reg2_output :
                (reg2_judge == `REG2_MUX_WB) ? wb_data :
                (reg2_judge == `REG2_MUX_IMM) ? imm : 
                32'b0;
endmodule

module mux_imem_read(
    input pc30,
    input [31:0] imem_out,
    input [31:0] bios_out,
    output [31:0] inst_output
);
    assign inst_output = (pc30 == 1'b0) ? imem_out : bios_out;
endmodule


`endif
