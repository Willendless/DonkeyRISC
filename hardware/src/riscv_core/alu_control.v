module alu_control(
    input [2:0] imm,
    input imm30,
    input [1:0] aluOp,
    output [3:0] aluCtrl
)

wire [3:0] func_imm;

assign aluCtrl = (aluOp == 2'b00) ? 4'b0010:
                 (aluOp == 2'b01) ? 4'b0110:
                 func_imm;

wire [3:0] r_imm = (imm30 == 1) ? 4'b0100 : 4'b0010;

assign func_imm = (imm == 3'b000) ? r_imm:
                  (imm == 3'b111) ? 4'b0000:
                  (imm == 3'b110) ? 4'b0001;

endmodule