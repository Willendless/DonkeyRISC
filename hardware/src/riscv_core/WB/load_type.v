`include "../defines.vh"
`include "../Opcode.vh"
module load_type (
    input [1:0] addr_offset,
    input [2:0] control_load,
    input [31:0] dmem_load_i,
    output [31:0] dmem_data_o
);
wire [31:0] dmem_lw;
assign dmem_lw = dmem_load_i;

wire [31:0] dmem_data_mv;
assign dmem_data_mv = (addr_offset == 2'b00) ? dmem_load_i :
                      (addr_offset == 2'b01) ? dmem_load_i >> 8 :
                      (addr_offset == 2'b10) ? dmem_load_i >> 16 :
                      dmem_load_i >> 16;

wire [31:0] dmem_data_mv1 = (addr_offset == 2'b00) ? {24'b0, dmem_load_i[7:0]} :
                     (addr_offset == 2'b01) ? {24'b0, dmem_load_i[15:8]} :
                     (addr_offset == 2'b10) ? {24'b0, dmem_load_i[23:16]} :
                     {24'b0, dmem_load_i[31:24]};

wire [31:0] dmem_lh = {{16{dmem_load_i[15]}}, dmem_data_mv[15:0]};
wire [31:0] dmem_lhu = {16'b0, dmem_data_mv[15:0]};
wire [31:0] dmem_lb = {{24{dmem_load_i[7]}}, dmem_data_mv1[7:0]};
wire [31:0] dmem_lbu = {24'b0, dmem_data_mv1[7:0]};

assign dmem_data_o = (control_load == `DMEM_LW) ? dmem_lw :
                     (control_load == `DMEM_LB) ? dmem_lb :
                     (control_load == `DMEM_LH) ? dmem_lh :
                     (control_load == `DMEM_LBU) ? dmem_lbu :
                     (control_load == `DMEM_LHU) ? dmem_lhu :
                     32'b0;

endmodule