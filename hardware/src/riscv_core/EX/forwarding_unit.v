`include "../defines.vh"

module forwarding_unit(
    input [4:0] reg1_addr,
    input [4:0] reg2_addr,
    input [4:0] wb_addr,
    input is_wb,
    input [1:0] control_forward,
    output [1:0] reg1_judge,
    output [1:0] reg2_judge,
    output mem_wdata_judge
);


assign reg1_judge = (reg1_addr === wb_addr &&
                    (control_forward === `FORWARD_REG || control_forward === `FORWARD_STORE)
                    && is_wb === 1'b1) ? `REG1_MUX_WB :
                    (control_forward == `FORWARD_PC1) ? `REG1_MUX_PC :
                    `REG1_MUX_REG;

assign reg2_judge = (reg2_addr == wb_addr && control_forward == `FORWARD_REG) ? `REG2_MUX_WB :
                    (control_forward === `FORWARD_IMM || control_forward === `FORWARD_PC1 || control_forward === `FORWARD_STORE) ? `REG2_MUX_IMM :
                    `REG2_MUX_REG;

assign mem_wdata_judge = (reg2_addr === wb_addr && control_forward === `FORWARD_STORE && is_wb);

endmodule