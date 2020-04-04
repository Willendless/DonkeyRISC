`include "../defines.vh"

module alu(
    input [31:0] aluin1,
    input [31:0] aluin2,
    output [31:0] aluout,
    input [3:0] aluCtrl
);

wire [31:0] alu_add;
wire [31:0] alu_sub;
wire [31:0] alu_or;
wire [31:0] alu_and;
wire [31:0] alu_sll;
wire [31:0] alu_slt;
wire [31:0] alu_sltu;
wire [31:0] alu_xor;
wire [31:0] alu_srl;
wire [31:0] alu_sra;

assign alu_add = aluin1 + aluin2;
assign alu_sub = aluin1 - aluin2;
assign alu_or = aluin1 | aluin2;
assign alu_and = aluin1 & aluin2;
assign alu_sll = aluin1 << aluin2;
assign alu_sra = aluin1 >> aluin2;//how?
assign alu_srl = aluin1 >>> aluin2;
assign alu_xor = aluin1 ^ aluin2;
assign alu_slt = (aluin1 < aluin2) ? 1 : 0;

wire input_sign1 = aluin1[31];
wire input_sign2 = aluin2[31];
wire [31:0] alu_sign1;
wire [31:0] alu_sign2;
assign alu_sign1 = (input_sign1 == 1) ? (32'hffffffff - aluin1) : aluin1;
assign alu_sign2 = (input_sign2 == 1) ? (32'hffffffff - aluin2) : aluin2;
assign alu_sltu = (input_sign1 == 1 && input_sign2 == 0) ? 0 :
                  (input_sign1 == 0 && input_sign2 == 1) ? 1 :
                  (input_sign1 == 1 && input_sign2 == 1 && alu_sign1 >= alu_sign2) ? 1 :
                  (input_sign1 == 1 && input_sign2 == 1 && alu_sign1 < alu_sign2) ? 0 :
                  (input_sign1 == 0 && input_sign2 == 0 && alu_sign1 >= alu_sign2) ? 0 :
                  1;
                
assign aluout = (aluCtrl == `ALUCTRL_AD) ? alu_add:
                (aluCtrl == `ALUCTRL_OR) ? alu_or:
                (aluCtrl == `ALUCTRL_SLL) ? alu_sll:
                (aluCtrl == `ALUCTRL_SUB) ? alu_sub:
                (aluCtrl == `ALUCTRL_SLT) ? alu_slt:
                (aluCtrl == `ALUCTRL_SLTU) ? alu_sltu:
                (aluCtrl == `ALUCTRL_XOR) ? alu_xor:
                (aluCtrl == `ALUCTRL_AND) ? alu_and:
                (aluCtrl == `ALUCTRL_SRL) ? alu_srl:
                (aluCtrl == `ALUCTRL_SRA) ? alu_sra:
                0;

endmodule

