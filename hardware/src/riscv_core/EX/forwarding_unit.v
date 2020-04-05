`include "../defines.vh"

module forwarding_unit(
    input [4:0] reg1_addr,
    input [4:0] reg2_addr,
    input [4:0] wb_addr,
    input [1:0] control_forward,
    output [1:0] reg1_judge,
    output [1:0] reg2_judge
);


assign reg1_judge = (reg1_addr == reg2_addr && control_forward == `FORWARD_REG1) ? `REG1_MUX_WB :
                    (control_forward == `FORWARD_PC1) ? `REG1_MUX_PC :
                    `REG1_MUX_REG;
assign reg2_judge = (control_forward == `FORWARD_IMM || `FORWARD_PC1) ? `REG2_MUX_IMM ://no hazard, imm
                    (reg2_addr == wb_addr && control_forward == `FORWARD_REG2) ? `REG2_MUX_WB ://data hazard
                    `REG2_MUX_REG;//imm

endmodule