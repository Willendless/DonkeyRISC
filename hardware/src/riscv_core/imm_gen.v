module imm_gen(
    input [11:0] inst_origin,
    output [31:0] imm
)

assign imm[10:0] = inst_origin[10:0];
assign imm[31:11] = inst_origin[11]<<20;

endmodule