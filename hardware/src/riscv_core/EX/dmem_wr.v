`include "../defines.vh"
`include "../Opcode.vh"
module dmem_wr (
    input control_dmem,
    input [2:0] funct3_i,
    input [1:0] addr_offset,
    output [3:0] dmem_we
);

wire [3:0] sb = (addr_offset == 2'b00) ? 4'b0001 :
                (addr_offset == 2'b01) ? 4'b0010 :
                (addr_offset == 2'b10) ? 4'b0100 :
                4'b1000;
wire [3:0] sh = (addr_offset == 2'b00) ? 4'b0011 :
                (addr_offset == 2'b01) ? 4'b0110 :
                (addr_offset == 2'b10) ? 4'b1100 :
                4'b1100;
wire [3:0] sw = 4'b1111;
assign dmem_we = (control_dmem == 1'b1 && funct3_i == `FNC_SB) ? sb : //sb
                 (control_dmem == 1'b1 && funct3_i == `FNC_SH) ? sh : //sb
                 (control_dmem == 1'b1 && funct3_i == `FNC_SW) ? sw :
                 4'b0000;


endmodule //sb