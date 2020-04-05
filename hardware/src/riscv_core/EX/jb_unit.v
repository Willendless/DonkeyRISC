module jb_unit(
    input [1:0] control_jump,
    input branch_comp_result,
    output [1:0] jump_judge,
    output if_flush
);

assign jump_judge[0] = branch_comp_result && control_jump[1];
assign jump_judge[1] = control_jump[0];
assign if_flush = jump_judge[0] || jump_judge[1];
endmodule