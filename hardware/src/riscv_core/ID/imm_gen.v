`include "../Opcode.vh"
`include "../defines.vh"

module imm_gen (
    input wire[`INST_BUS] opcode_i,
    output reg[`IMM32_BUS] imm,
    output reg[`IMM32_BUS] branch_offset
);
    always @(*) begin
        imm = `IMM32_WIDTH'b0;
        branch_offset = `HALF_WORD_WIDTH'b0;
        case (opcode_i[`FIELD_OPCODE_5])
            // I-type
            `OPC_JALR_5, `OPC_LOAD_5,
            `OPC_ARI_ITYPE_5: imm = {{21{opcode_i[31]}}, opcode_i[30:20]};
            // S-type
            `OPC_STORE_5: imm = {{21{opcode_i[31]}}, opcode_i[30:25], opcode_i[11:8], opcode_i[7]};
            // B-type
            `OPC_BRANCH_5: branch_offset = {{20{opcode_i[31]}}, opcode_i[7], opcode_i[30:25], opcode_i[11:8], 1'b0};
            // J-type
            `OPC_JAL_5: imm = {{12{opcode_i[31]}}, opcode_i[19:12], opcode_i[20], opcode_i[30:25], opcode_i[24:21], 1'b0};
            // U-type
            `OPC_LUI_5,
            `OPC_AUIPC_5: imm = {opcode_i[31], opcode_i[30:20], opcode_i[19:12], {12{1'b0}}};
            // CSR_type
            `OPC_CSR_5: imm = {27'b0 ,opcode_i[19:15]};
            // R-type
            `OPC_ARI_RTYPE_5: ;
            default: ; 
        endcase
    end

endmodule
