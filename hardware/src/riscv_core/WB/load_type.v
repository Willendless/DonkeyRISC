`include "../defines.vh"
module load_type (
    input [2:0] control_load,
    input [31:0] dmem_load_i,
    output [31:0] dmem_data_o
);
wire [31:0] dmem_lw;
assign dmem_lw = dmem_load_i;
wire [31:0] dmem_lh = {{16{dmem_load_i[15]}}, dmem_load_i[15:0]};
wire [31:0] dmem_lhu = {16'b0, dmem_load_i[15:0]};
wire [31:0] dmem_lb = {{24{dmem_load_i[7]}}, dmem_load_i[7:0]};
wire [31:0] dmem_lbu = {24'b0, dmem_load_i[7:0]};

assign dmem_data_o = (control_load === `DMEM_LW) ? dmem_lw :
                     (control_load === `DMEM_LB) ? dmem_lb :
                     (control_load === `DMEM_LH) ? dmem_lh :
                     (control_load === `DMEM_LBU) ? dmem_lbu :
                     (control_load === `DMEM_LHU) ? dmem_lhu :
                     32'b0;

endmodule