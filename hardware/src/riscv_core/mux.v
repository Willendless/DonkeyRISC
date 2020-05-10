`ifndef MUX
`define MUX
`include "../defines.vh"
`include "../Opcode.vh"
module mux_dmem(
    input [31:0] dmem_output,
    input [31:0] bios_output,
    input [31:0] pc_output,
    input [31:0] rtype_output,
    output [31:0] wb_data,

    input [1:0] control_data,
    input [3:0] addr
);
//writeback mux
assign wb_data = (control_data == 2'b01) ? rtype_output://choose the result of alu
                 (control_data == 2'b11) ? pc_output://choose the result of jal / jalr
                 (control_data == 2'b10 && (addr == 4'b0001 || addr == 4'b0011)) ? dmem_output://choose the result of dmem
                 (control_data == 2'b10 && addr == 4'b0100) ? bios_output://choose bios memory
                 32'b0;
endmodule

module mux_pc(
    input [31:0] pc_plus,
    input [31:0] pc_plus_reg,
    input [31:0] jal_addr,
    input [31:0] branch_addr,
    input [31:0] branch_addr_after,
    input [1:0] jump_judge,
    input [1:0] branch_predict_i,
    input branch_judge,
    input clk, 
    input rst,
    output reg [31:0] pc_o,
    output reg flush_wrong
);
//define the input of jump signal
wire [31:0] pc_normal;

wire [1:0] branch_predict_before;
REGISTER_R #(.N(2), .INIT(2'b0)) store_predict(
    .q(branch_predict_before),
    .d(branch_predict_i),
    .rst(rst),
    .clk(clk)
);



always @(*) begin
    flush_wrong <= 1'b0;
    pc_o <= pc_plus;
    if (branch_judge == 1) begin
        case(branch_predict_before)
            2'b10: pc_o <= pc_normal;
            2'b01: begin 
            pc_o <= branch_addr_after;
            flush_wrong <= 1'b1;
            end
            default: pc_o <= pc_normal;
        endcase
    end
    else begin
    case(branch_predict_before)
        2'b00: begin
            if (branch_predict_i == 2'b10)
                pc_o <= branch_addr;
            else
                pc_o <= pc_normal;
            end
        2'b01: begin
            if (branch_predict_i == 2'b10)
                pc_o <= branch_addr;
            else
                pc_o <= pc_normal;
            end
        2'b10: begin
                flush_wrong = 1'b1;
                pc_o <= pc_plus_reg;
            end
    endcase
    end
end

assign pc_normal = (jump_judge > 0) ? jal_addr : pc_plus;

endmodule

module mux_reg1(
    input [31:0] wb_data,
    input [31:0] reg1_output,
    input [31:0] pc_output,
    input [1:0] reg1_judge,
    output [31:0] aluin1
);

assign aluin1 = (reg1_judge == `REG1_MUX_REG) ? reg1_output :
                (reg1_judge == `REG1_MUX_WB) ? wb_data : 
                (reg1_judge == `REG1_MUX_PC) ? pc_output : 
                32'b0;
endmodule

module mux_reg2(
    input [31:0] imm,
    input [31:0] reg2_output,
    input [31:0] wb_data,
    input [1:0] reg2_judge,
    output [31:0] aluin2
);

assign aluin2 = (reg2_judge == `REG2_MUX_REG) ? reg2_output :
                (reg2_judge == `REG2_MUX_WB) ? wb_data :
                (reg2_judge == `REG2_MUX_IMM) ? imm : 
                32'b0;
endmodule

module mux_imem_read(
    input pc30,
    input [31:0] imem_out,
    input [31:0] bios_out,
    output [31:0] inst_output
);
    assign inst_output = (pc30 == 1'b0) ? imem_out : bios_out;
endmodule


`endif
