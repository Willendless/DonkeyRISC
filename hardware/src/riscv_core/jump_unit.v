module jump_unit(
    input [1:0] control_jump,
    input branch_judge,
    output jump_judge
);
//control_jump[0] stand for jal or jalr
//control_jump[1] stand for branch
wire is_branch = control_jump[1] && branch_judge;
assign jump_judge = is_branch || control_jump[0];

endmodule

