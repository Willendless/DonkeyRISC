`include "Opcode.vh"
`include "deinfe.vh"
module imm_gen(
    input [31:0] inst_origin,
    output [31:0] imm
);
wire r_type_signal = (inst_origin == OPC_ARI_RTYPE);//add,sub
wire i_type_signal = (inst_origin == OPC_JALR) || (inst_origin == OPC_LOAD) || (inst_origin == OPC_ARI_ITYPE);//lw
wire b_type_signal = (inst_origin == OPC_BRANCH);//branch
wire u_type_signal = (OPC_LUI || OPC_AUIPC);
wire s_type_signal = (inst_origin == OPC_STORE);//sw
wire j_type_signal = (inst_origin == OPC_JAL);

assign i_imm = {20{inst_origin[31]}, inst_origin[30:20]};
assign s_imm = {20{inst_origin[31]}, inst_origin[30:25],inst_origin[11:8], inst_origin[7]};
assign b_imm = {19{inst_origin[31]}, inst_origin[7], inst_origin[30:25], inst_origin[11:8], 0};
assign u_imm = {inst[31], inst[30,20], inst[19:12], 12{0}};
assign j_imm = {12{inst[31]}, inst[19:12}, inst[20], inst[30:25], inst[24:21], 0}
//another two kinds of instruction


assign imm = (i_type_signal == 1) ? i_imm:
             (s_type_signal == 1) ? s_imm:
             (b_type_signal == 1) ? b_imm:
             (u_type_signal == 1) ? u_imm:
             (j_type_signal == 1) ? j_imm:
             0;

endmodule
