`include "../Opcode.vh"
`include "../defines.vh"

/*
*   TODO:
*   id stage file, connect to id_ex
*   @OUTPUT:
*   reg1_data
*   reg2_data
*   imm
*   wb_addr
*   alu_op
*   //write_back enable
*   
*/
module id (
    input wire[`IMEM_DBUS] inst_i,

    // reg data from regfile
    input wire[`REG_DBUS] reg1_data_i,
    input wire[`REG_DBUS] reg2_data_i,
    // reg addr to regfile
    output wire[`REG_ABUS] reg1_addr_o,
    output wire[`REG_ABUS] reg2_addr_o,
    // reg data to id_ex
    output wire[`REG_DBUS] reg1_data_o,
    output wire[`REG_DBUS] reg2_data_o,

    output wire wb_en_o, //*
    output wire[`IMM_BUS] imm_o,
    output wire[`REG_DBUS] wb_addr_o
);

    // decocde
    wire[`REG_ABUS] inst_rd, inst_rs1, inst_rs2;
    wire[`FIELD_OPCODE] inst_opcode;

    assign  inst_rd     = inst_i[`FIELD_RD],
            inst_rs1    = inst_i[`FIELD_RS1],
            inst_rs2    = inst_i[`FIELD_RS2],
            inst_opcode = inst_i[`FIELD_OPCODE];

    // next pc

    // write back addr
    assign  wb_addr_o = inst_rd;

    // reg_file

    assign  reg1_addr_o = inst_rs1,
            reg2_addr_o = inst_rs2;

    assign  reg1_data_o = reg1_data_i,
            reg2_data_o = reg2_data_i;    
    

    // control_unit
    control_unit control (
        .inst(inst_opcode),
        .control_forward(),
        .aluOp(),
        .control_uart(),
        .control_dmem(),
        .control_wr_mux()
    );

    // imm_gen
    imm_gen imm (
        .inst_origin(inst_i),
        .imm(imm_o)
    );


endmodule