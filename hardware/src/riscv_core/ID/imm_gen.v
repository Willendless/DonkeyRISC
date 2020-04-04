`include "../Opcode.vh"
`include "../defines.vh"

module imm_gen (
    input wire[`INST_BUS] inst_i,
    output reg[`IMM32_BUS] imm
);

    always @(*) begin
        imm = `IMM32_WIDTH'b0;
        case (inst_i[`FIELD_OPCODE_5])
            // I-type
            `OPC_JALR_5, `OPC_LOAD_5,
            `OPC_ARI_ITYPE_5: imm = {{21{inst_i[31]}}, inst_i[30:20]};
            // S-type
            `OPC_STORE_5: imm = {{20{inst_i[31]}}, inst_i[30:25],inst_i[11:8], inst_i[7]};
            // B-type
            `OPC_BRANCH_5: imm = {{19{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 0};
            // J-type
            `OPC_JAL_5: imm = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:25], inst_i[24:21], 0};
            // U-type
            `OPC_LUI_5,
            `OPC_AUIPC_5: imm = {inst_i[31], inst_i[30:20], inst_i[19:12], {12{0}}};
            // R-type
            `OPC_ARI_RTYPE_5: ;
            default: ; 
        endcase
    end

endmodule
