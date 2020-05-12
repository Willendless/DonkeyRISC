`include "../defines.vh"
`include "../Opcode.vh"

module alu(
    input [31:0] aluin1,
    input [31:0] aluin2,
    output [31:0] aluout,
    output [31:0] alu_addr_out,
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

assign alu_add = ($signed(aluin1)) + ($signed(aluin2));
assign alu_sub = aluin1 - aluin2;
assign alu_or = aluin1 | aluin2;
assign alu_and = aluin1 & aluin2;
assign alu_sll = aluin1 << aluin2[4:0];
assign alu_sra = ($signed(aluin1)) >>> aluin2[4:0];//how?
assign alu_srl = aluin1 >> aluin2[4:0];
assign alu_xor = aluin1 ^ aluin2;
assign alu_sltu = (aluin1 < aluin2) ? 32'b1 : 32'b0;

wire input_sign1 = aluin1[31];
wire input_sign2 = aluin2[31];
//wire [31:0] alu_sign1;
//wire [31:0] alu_sign2;
//assign alu_sign1 = (input_sign1 == 1) ? (32'hffffffff - aluin1) : aluin1;
//assign alu_sign2 = (input_sign2 == 1) ? (32'hffffffff - aluin2) : aluin2;
assign alu_slt = (input_sign1 == 1 && input_sign2 == 0) ? 32'b1 :
                  (input_sign1 == 0 && input_sign2 == 1) ? 32'b0 :
                  (input_sign1 == 1 && input_sign2 == 1 && aluin1 < aluin2) ? 32'b1 :
                  (input_sign1 == 1 && input_sign2 == 1 && aluin1 >= aluin2) ? 32'b0 :
                  (input_sign1 == 0 && input_sign2 == 0 && aluin1 >= aluin2) ? 32'b0 :
                  32'b1;

reg [31:0] aluout1;
reg [31:0] aluout2;

always @(*) begin
    aluout1 = 32'b0;
    case(aluCtrl)
    `ALUCTRL_ADD: aluout1 = alu_add;
    `ALUCTRL_OR: aluout1 = alu_or;
    `ALUCTRL_SLL: aluout1 = alu_sll;
    `ALUCTRL_SUB: aluout1 = alu_sub;
    `ALUCTRL_SLT: aluout1 = alu_slt;
    `ALUCTRL_SLTU: aluout1 = alu_sltu;
    `ALUCTRL_XOR: aluout1 = alu_xor;
    `ALUCTRL_AND: aluout1 = alu_and;
    `ALUCTRL_SRL: aluout1 = alu_srl;
    `ALUCTRL_SRA: aluout1 = alu_sra;
    4'b1111: aluout1 = aluin2;
    default: aluout1 = 32'b0;
    endcase
end

always @(*) begin
    aluout2 <= alu_add;
end

assign aluout = aluout1;
assign alu_addr_out = aluout2;

endmodule

