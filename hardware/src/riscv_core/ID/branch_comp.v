`include "../defines.vh"
module branch_comp(
    input [2:0] branch_type,
    input [31:0] a,
    input [31:0] b,
    input is_branch,
    output reg branch_judge 
);
initial begin
    branch_judge = 0;

    always @(*) begin
        if (is_branch == 1) begin
            case(branch_type)
            `BEQ: branch_judge = (a == b);
                `BGE: begin
                if (a[31] == 0 && b[31] == 0)
                    branch_judge = (a >= b);
                else if (a[31] == 1 && b[31] == 1)
                    branch_judge = (a <= b);
                else if (a[31] == 0 && b[31] == 1)
                    branch_judge = 0;
                else
                    branch_judge = 1;
                end
            `BGEU: branch_judge = (a >= b);
            `BLT: begin
                if (a[31] == 0 && b[31] == 0)
                    branch_judge = (a < b);
                else if (a[31] == 1 && b[31] == 1)
                    branch_judge = (a >= b);
                else if (a[31] == 0 && b[31] == 1)
                    branch_judge = 1;
                else
                    branch_judge = 0;
                end
            `BLTU: branch_judge = (a < b);
            `BNE: branch_judge = ~(a==b);
            endcase
        end else begin
            branch_judge = 1'b0;
        end
    end

endmodule