`include "../defines.vh"
`include "../Opcode.vh"

module alu_control(
    input [2:0] inst_alu,
    input inst_alu30,
    input [1:0] aluOp,
    output [3:0] aluCtrl
);

wire [3:0] func_imm;
wire [3:0] func_imm1;

assign aluCtrl = (aluOp == `ALUOP_RTYPE) ? func_imm:
                 (aluOp == `ALUOP_ISJTYPE) ? `ALUCTRL_ADD:
                 (aluOp == `ALUOP_ADTYPE) ? func_imm1:
                 4'b1111;

assign func_imm = (inst_alu == `FNC_ADD_SUB && inst_alu30 == `FNC2_ADD) ? `ALUCTRL_ADD:
                  (inst_alu == `FNC_ADD_SUB && inst_alu30 == `FNC2_SUB) ? `ALUCTRL_SUB:
                  (inst_alu == `FNC_SLL) ? `ALUCTRL_SLL:
                  (inst_alu == `FNC_SLT) ? `ALUCTRL_SLT:
                  (inst_alu == `FNC_SLTU) ? `ALUCTRL_SLTU:
                  (inst_alu == `FNC_XOR) ? `ALUCTRL_XOR:
                  (inst_alu == `FNC_OR) ? `ALUCTRL_OR:
                  (inst_alu == `FNC_AND) ? `ALUCTRL_AND:
                  (inst_alu == `FNC_SRL_SRA && inst_alu30 == `FNC2_SRL) ? `ALUCTRL_SRL:
                  (inst_alu == `FNC_SRL_SRA && inst_alu30 == `FNC2_SRA) ? `ALUCTRL_SRA:
                  4'b1111;

assign func_imm1 = (inst_alu == `FNC_ADD_SUB) ? `ALUCTRL_ADD:
                  (inst_alu == `FNC_SLL) ? `ALUCTRL_SLL:
                  (inst_alu == `FNC_SRL_SRA && inst_alu30 == `FNC2_SRL) ? `ALUCTRL_SRL:
                  (inst_alu == `FNC_SRL_SRA && inst_alu30 == `FNC2_SRA) ? `ALUCTRL_SRA:                 
                  (inst_alu == `FNC_SLT) ? `ALUCTRL_SLT:
                  (inst_alu == `FNC_SLTU) ? `ALUCTRL_SLTU:
                  (inst_alu == `FNC_XOR) ? `ALUCTRL_XOR:
                  (inst_alu == `FNC_OR) ? `ALUCTRL_OR:
                  (inst_alu == `FNC_AND) ? `ALUCTRL_AND:
                  4'b1111;                                                   
endmodule