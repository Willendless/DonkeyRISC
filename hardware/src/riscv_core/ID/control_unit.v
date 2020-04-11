`include "../defines.vh"
`include "../Opcode.vh"
/**
* control_unit.v
* control unit of cpu, feed control signal of each stage's mux
*   @OUTPUT:
* // inst type
*   
* // ex stage muxes
*   alu_op: output to alu_control
*   alu_src1_sel: forward from WRITE BACK stage
*   alu_src2_sel: reg2 or imm
*   mem_read -> load
*   mem_write  -> store
* // wb stage muxes
*   (inst_type, funct3)->wb_sel
*   wb_enable
* // pc & IMEM/BIOS
*   pc_sel
*/



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
    output control_uart, //TODO
    output control_dmem,
    output [1:0] control_wr_mux,
    output wire control_csr_we,
    output [2:0] control_load,
    output control_branch,
    output control_wb

// modification
/*
    output alu_src1_sel_o,
    output alu_src2_sel_o,
    output mem_read_o,
    output mem_write_o,
    output wb_enable_o
    //output pc_sel*/

);

/*
    always @(*) begin
        alu_src1_sel_o = 1'b0;
        alu_src2_sel_o = 1'b0;
        mem_read_o = 1'b0;
        mem_write_o = 1'b0;
        wb_enable_o = 1'b0;
        case (opcode[`FIELD_OPCODE_5])
            `OPC_ARI_RTYPE_5: begin
                wb_enable_o = 1'b1;
            end 
            default: ;
        endcase
        
    end
*/
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

assign alu_op = (i_type_signal_lw || s_type_signal || 
                j_type_signal || i_type_signal_jalr ||
                csr_type_signal || u_type_signal) ? `ALUOP_ISJTYPE ://lw and sw type
                (r_type_signal) ? `ALUOP_RTYPE :
                (i_type_signal_addi) ? `ALUOP_ADTYPE ://branch type
                2'b11;//calculate type

assign control_jump[0] = i_type_signal_jalr;
assign control_jump[1] = j_type_signal;

assign control_wr_mux = (r_type_signal || i_type_signal_addi
                        || u_type_signal || l_type_signal) ? 2'b01: //add r-type inst
                      i_type_signal_lw ? 2'b10: //lw l-type inst
                      (j_type_signal || i_type_signal_jalr) ? 2'b11: // jal
                      2'b00;

assign control_uart = (i_type_signal_lw || s_type_signal);//read from uart

assign control_dmem = s_type_signal;//write enable data used for sw inst

assign control_csr_we = csr_type_signal;

assign control_branch = b_type_signal;

always @(*) begin
    case(opcode)
    `OPC_STORE: control_forward = `FORWARD_STORE;
    `OPC_LOAD: control_forward = `FORWARD_IMM;
    `OPC_BRANCH: control_forward = `FORWARD_REG;
    `OPC_JAL: control_forward = `FORWARD_PC1;
    `OPC_JALR: control_forward = `FORWARD_IMM;
    `OPC_ARI_RTYPE: control_forward = `FORWARD_REG;
    `OPC_ARI_ITYPE: control_forward = `FORWARD_IMM;
    `OPC_LUI: control_forward = `FORWARD_IMM;
    `OPC_AUIPC: control_forward = `FORWARD_PC1;
    default: control_forward = `FORWARD_REG;
    endcase
end

assign control_load = (i_type_signal_lw && (funct3_i == `FNC_LB)) ? `DMEM_LB :
                      (i_type_signal_lw && (funct3_i == `FNC_LH)) ? `DMEM_LH :
                      (i_type_signal_lw && (funct3_i == `FNC_LW)) ? `DMEM_LW :
                      (i_type_signal_lw && (funct3_i == `FNC_LBU)) ? `DMEM_LBU :
                      (i_type_signal_lw && (funct3_i == `FNC_LHU)) ? `DMEM_LHU :
                      3'b000;

assign control_wb = (b_type_signal || s_type_signal) ? 1'b0 : 1'b1;

endmodule