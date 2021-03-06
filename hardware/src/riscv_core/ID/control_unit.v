`include "../defines.vh"
`include "../Opcode.vh"
/**
*   1. Integer Computational Instructions
*   - Register-Register
*       - R-type
*           funct7  rs2 rs1 funct3  rd  opcode
*           OP(rs1, rs2)------->rd
*           op: determine by funct3 & funct7
*               - ADD/SLT/SLTU
*               - AND/OR/XOR
*               - SLL/SRL
*               - SUB/SRA
*   - Register-Imm
*       - I-type
*           imm[11:0]   rs1 funct3  rd  opcode
*           OP-IMM(rs1, rd)--------->rd
*           op: determine by funct3
*               - ADDI/SLTI[U]: (sign extended and treated as unsigned)
*               - ANDI/ORI/XORI
*           imm[11:5]   imm[4:0]    rs1 funct3  rd  opcode
*               - SLLI
*               - SRLI
*               - SRAI
*       -U-type
*           U-imm[31:12]  rd  opcode
*           - LUI(load upper immediate): use to build 32bit constants 
*               zero filled low 12bits
*           - AUIPC(add upper immediate to pc): use to build pc-relative addresses
*               zero filled low 12bits
*   - Nop
*       imm[11:0]   rs1 funct3  rd  opcode
*       0           0   ADDI    0   OP-IMM
*
*   //TODO:
*   2. Control Transfer Instructions 
*   3. Load and Store Instructions
*/          

module control_unit (
    input [`FIELD_OPCODE] opcode,
    input [2:0] funct3_i,

    output reg [1:0] control_forward,
    output [1:0] control_jump,
    output [1:0] alu_op,
    output [1:0] control_uart, //TODO
    output control_dmem,
    output [1:0] control_wr_mux,
    output wire control_csr_we,
    output [2:0] control_load,
    output control_branch,
    output control_wb

);

initial begin
    control_forward = 2'b0;
end

wire r_type_signal = (opcode == 7'b0110011);//add,sub
wire i_type_signal_lw = (opcode == 7'b0000011);//lw etc
wire b_type_signal = (opcode == 7'b1100011);//branch
wire i_type_signal_addi = (opcode == 7'b0010011);//addi etc
wire i_type_signal_jalr = (opcode == 7'b1100111);//jalr
wire s_type_signal = (opcode == 7'b0100011);//sw
wire j_type_signal = (opcode == 7'b1101111);//jal
wire u_type_signal = (opcode == 7'b0010111);
wire l_type_signal = (opcode == 7'b0110111);

wire csr_type_signal = (opcode == `OPC_CSR);

wire opc_lui_signal = (opcode == 7'b0110111);
wire opc_auipc_signal = (opcode == 7'b0010111);

wire is_stype;
assign is_stype = (i_type_signal_lw || s_type_signal || 
                j_type_signal || i_type_signal_jalr ||
                csr_type_signal || u_type_signal);

assign alu_op = is_stype ? `ALUOP_ISJTYPE ://lw and sw type
                (r_type_signal) ? `ALUOP_RTYPE :
                (i_type_signal_addi) ? `ALUOP_ADTYPE ://branch type
                2'b11;//calculate type

assign control_jump[0] = i_type_signal_jalr;
assign control_jump[1] = j_type_signal;

wire choose_rtype = (r_type_signal || i_type_signal_addi
                    || u_type_signal || l_type_signal);
wire choose_itype = i_type_signal_lw;
wire choose_jtype = (j_type_signal || i_type_signal_jalr);

assign control_wr_mux =  choose_rtype ? 2'b01: //add r-type inst
                         choose_itype ? 2'b10: //lw l-type inst
                         choose_jtype ? 2'b11: // jal
                         2'b00;

assign control_uart = (i_type_signal_lw == 1) ? 2'b01://lw receiver 2'b01
                      (s_type_signal == 1) ? 2'b10:
                      2'b00;

assign control_dmem = s_type_signal;//write enable data used for sw inst

assign control_csr_we = csr_type_signal;

assign control_branch = b_type_signal;

wire forward_pc;
wire forward_store;
wire forward_imm;
wire forward_reg;

assign forward_pc = (opcode == `OPC_JAL || opcode == `OPC_AUIPC);
assign forward_store = (opcode == `OPC_STORE);
assign forward_imm = (opcode == `OPC_LOAD || 
                      opcode == `OPC_ARI_ITYPE ||
                      opcode == `OPC_JALR || 
                      opcode == `OPC_LUI);
assign forward_reg = (opcode == `OPC_BRANCH ||
                      opcode == `OPC_ARI_RTYPE || 
                      opcode == `OPC_CSR);




always @(*) begin
    if (forward_pc == 1'b1) begin
    control_forward = `FORWARD_PC1;
    end else if (forward_imm == 1'b1) begin
    control_forward = `FORWARD_IMM;
    end else if (forward_reg == 1'b1) begin
    control_forward = `FORWARD_REG;
    end else if (forward_store == 1'b1) begin
    control_forward = `FORWARD_STORE;
    end else begin
    control_forward = `FORWARD_REG;
    end

end

assign control_load = (i_type_signal_lw && (funct3_i == `FNC_LB)) ? `DMEM_LB :
                      (i_type_signal_lw && (funct3_i == `FNC_LH)) ? `DMEM_LH :
                      (i_type_signal_lw && (funct3_i == `FNC_LW)) ? `DMEM_LW :
                      (i_type_signal_lw && (funct3_i == `FNC_LBU)) ? `DMEM_LBU :
                      (i_type_signal_lw && (funct3_i == `FNC_LHU)) ? `DMEM_LHU :
                      3'b000;

assign control_wb = (b_type_signal || s_type_signal) ? 1'b0 : 1'b1;

endmodule