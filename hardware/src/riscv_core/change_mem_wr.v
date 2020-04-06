module change_mem_wr(
    input [3:0] dmem_we,
    input [31:0] in_data,
    output reg [31:0] out_data
    );

integer i;
integer j = 0;

initial begin
    out_data = 32'b0;
end
always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
        if (dmem_we[i]) begin
            out_data[i*8 +: 8] = in_data[j*8 +: 8];
            j = j + 1;
        end
    end
    j = 0;
end
endmodule