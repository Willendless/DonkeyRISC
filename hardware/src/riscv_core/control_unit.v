`include "alu_control.v"
module control_unit (
    input [6:0] inst,
    output control_forward,
    output [1:0] control_jump,
    output [1:0] aluOp,
    output control_uart,
    output control_dmem,
    output [1:0] control_wr_mux
);

assign aluOp = (i_type_signal_lw || s_type_signal) ? 2'b00://lw and sw type
                   (b_type_signal) ? 2'b01 ://branch type
                   (r_type_signal);//calculate type
                   

wire r_type_signal = (inst == 7'b0110011);//add,sub
wire i_type_signal_lw = (inst == 7'b0000011);//lw etc
wire b_type_signal = (inst == 7'b1100011);//branch
wire i_type_signal_addi = (inst == 7'b0010011);//addi
wire i_type_signal_jalr = (inst == 7'b1100111);//jalr
wire s_type_signal = (inst == 7'b0100011);//sw
wire j_type_signal = (inst == 7'b1101111);//jal

wire opc_lui_signal = (inst == 7'b0110111);
wire opc_auipc_signal = (inst == 7'b0010111);

assign control_jump[0] = i_type_signal_jalr || j_type_signal;
assign control_jump[1] = b_type_signal;

assign control_wr_mux = r_type_signal ? 2'b01: //add r-type inst
                      i_type_signal_lw ? 2'b10: //lw l-type inst
                      (i_type_signal_jalr || j_type_signal) ? 2'b11: //jar jalr
                      3'b00;

assign control_uart = (i_type_signal || s_type_signal);//read from uart

assign control_dmem = s_type_signal;//write enable data used for sw inst

assign control_forward = r_type_signal ? 1 : 0;

endmodule