module jump_unit(
    input control_jump,
    input branch_judge,
    output [1:0] jump_judge
);

wire is_branch = control_jump && branch_judge;
assign jump_judge[0] = is_branch;
assign jump_judge[1] = control_jump;

endmodule

