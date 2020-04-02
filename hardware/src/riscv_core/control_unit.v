`include "alu_control.v"
module control_unit (
    input [6:0] inst,
    input imm30,
    input [2:0] imm,
    output control_forward,
    output control_jump,
    output aluCtrl,
    output control_uart,
    output [1:0] control_dmem,
    output control_wr_mux
)

assign control_forward = 0;
assign control_jump = 0;
assign control_dmem = 0;
assign control_uart = 0;
assign control_wr_mux = 0;

wire [1:0] aluOp = 2'b00;

wire r_type_signal = (inst == 7'b0110011);//add,sub
wire l_type_signal = (inst == 7'b0000011);//lw
wire b_type_signal = (inst == 7'b1100011);//branch
wire u_type_signal = (inst == 7'b0010011);
wire s_type_signal = (inst == 7'b0100011);//sw
wire j_type_signal = (inst == 7'b0110111);

assign control_jump = b_type_signal;

assign control_wr_mux = r_type_signal ? 2'b01: //add r-type inst
                      l_type_signal ? 2'b10: //lw l-type inst
                      b_type_signal ? 2'b11: //jar jalr
                      3'b00;

assign control_uart = (l_type_signal || s_type_signal);

assign control_dmem = l_type_signal;

assign control_forward = r_type_signal ? 1 : 0;


alu_control(.imm(imm), .imm30(imm30), .aluOp(aluOp), .aluCtrl(aluCtrl));

endmodule