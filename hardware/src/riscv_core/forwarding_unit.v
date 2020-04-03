module forwarding_unit(
    input [4:0] reg1_addr,
    input [4:0] reg2_addr,
    input [4:0] wb_addr,
    input control_forward,
    output reg1_judge,
    output [1:0] reg2_judge
);

assign reg1_judge = reg1_addr == wb_addr ? 1 : 0;
assign reg2_judge = (reg2_addr == wb_addr && control_forward == 1) ? 2'b01:
                    (reg2_addr == wb_addr && control_forward == 0) ? 2'b00:
                    2'b11;

endmodule