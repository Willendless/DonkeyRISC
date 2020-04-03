module mux_dmem(
    input [31:0] dmem_output,
    input [31:0] bios_output,
    input [31:0] pc_output,
    input [31:0] rtype_output,
    output [31:0] wb_data,

    input [1:0] control_data,
    input [3:0] addr
);

assign wb_data = (control_data == 2'b01) ? rtype_output:
                 (control_data == 2'b11) ? pc_output:
                 (control_data == 2'b10 && addr == 4'b00x1) ? dmem_output:
                 (control_data == 2'b10 && addr == 4'b0100) ? bios_output:
                 32'b0;
endmodule

module mux_pc(
    input [31:0] pc_plus,
    input [31:0] jal_addr,
    input [31:0] branch_addr,
    input [1:0] jump_judge,
    output [31:0] pc_in
);
assign pc_in = (jump_judge == 2'b10) ? jal_addr:
               (jump_judge == 2'b11) ? branch_addr:
               pc_plus;

endmodule

module mux_reg1(
    input [31:0] wb_data,
    input [31:0] reg1_output,
    input reg1_judge,
    output [31:0] aluin1
);

assign aluin1 = (reg1_judge == 1) ? wb_data : reg1_output;
endmodule

module mux_reg2(
    input [31:0] imm,
    input [31:0] reg2_output,
    input [31:0] wb_data,
    input [1:0] reg2_judge,
    output [31:0] aluin2
);

assign aluin2 = (reg2_judge == 2'b00) ? reg2_output :
                (reg2_judge == 2'b01) ? wb_data :
                imm;
endmodule

module mux_imem_read(
    input [31:0] imem_out,
    input [31:0] bios_out,
    output [31:0] inst_output,

    input pc30
);

assign inst_output = (pc30 == 1) ? imem_out : bios_out;
endmodule


