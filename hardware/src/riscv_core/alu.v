module alu(
    input [31:0] aluin1,
    input [31:0] aluin2,
    output [31:0] aluout,
    output branch_judge,
    input [4:0] aluCtrl
)

wire [31:0] alu_add;
wire [31:0] alu_sub;
wire [31:0] alu_or;
wire [31:0] alu_and;

assign alu_add = aluin1 + aluin2;
assign alu_sub = aluin1 - aluin2;
assign alu_or = aluin1 | aluin2;
assign alu_and aluin1 & aluin2;

assign aluout = (aluCtrl == 4'b0000) ? alu_add:
                (aluCtrl == 4'b0001) ? alu_or:
                (aluCtrl == 4'b0010) ? alu_add:
                (aluCtrl == 4'b0110) ? alu_sub;

assign branch_judge = aluin1 && aluin2;

endmodule

