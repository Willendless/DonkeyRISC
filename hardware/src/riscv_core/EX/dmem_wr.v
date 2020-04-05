module dmem_wr (
    input control_dmem,
    input [2:0] funct3_i,
    input [1:0] addr_offset,
    output [3:0] dmem_we
);

wire [2:0] sh_offset = (addr_offset < 2'b11) ? addr_offset : 2'b10;
assign dmem_we = (control_dmem == 1'b1 && funct3_i == 3'b000) ? (4'b0001 << addr_offset): //sb
                 (control_dmem == 1'b1 && funct3_i == 3'b001) ? (4'b0011 << sh_offset): //sb
                 (control_dmem == 1'b1 && funct3_i == 3'b010) ?  4'b1111 :
                 4'b0000;

endmodule //sb