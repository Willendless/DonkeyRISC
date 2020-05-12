module change_mem_wr(
    input [3:0] dmem_we,
    input [31:0] in_data,
    output reg [31:0] out_data
    );

always @(*) begin
    out_data = 32'b0;
    case(dmem_we)
        4'b1111: out_data = in_data;
        4'b0011: out_data = {16'b0, in_data[15:0]};
        4'b0110: out_data = {8'b0, in_data[15:0], 8'b0};
        4'b1100: out_data = {in_data[15:0], 16'b0};
        4'b0001: out_data = {24'b0, in_data[7:0]};
        4'b0010: out_data = {16'b0, in_data[7:0], 8'b0};
        4'b0100: out_data = {8'b0, in_data[7:0], 16'b0};
        4'b1000: out_data = {in_data[7:0], 24'b0};
        default: out_data = 32'b0;
    endcase
end
endmodule