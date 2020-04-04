module imm_gen(
    input [31:0] inst_origin,
    output [31:0] imm
);
wire r_type_signal = (inst_origin == 7'b0110011);//add,sub
wire i_type_signal = (inst_origin == 7'b0000011);//lw
wire b_type_signal = (inst_origin == 7'b1100011);//branch
wire u_type_signal = (inst_origin == 7'b0010011);
wire s_type_signal = (inst_origin == 7'b0100011);//sw
wire j_type_signal = (inst_origin == 7'b0110111);

assign i_imm = {{20{inst_origin[31]}}, inst_origin[30:20]};
assign s_imm = {20{inst_origin[31]}}, inst_origin[30:25],inst_origin[11:8], inst_origin[7]};
assign b_imm = {inst_origin[31]<<19, inst_origin[7], inst_origin[30:25], inst_origin[11:8], 0};

assign imm = (i_type_signal == 1) ? i_imm:
             (s_type_signal == 1) ? s_imm:
             (b_type_signal == 1) ? b_imm:
             0;
endmodule
