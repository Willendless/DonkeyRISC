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
    input wire[`IMEM_DBUS]      inst_i,
    input wire[`REG_DBUS]       pc_data_i,     

    // reg data from regfile
    input wire[`REG_DBUS] reg1_data_i,
    input wire[`REG_DBUS] reg2_data_i,
    // reg addr to regfile
    output wire[`REG_ABUS] reg1_addr_o,
    output wire[`REG_ABUS] reg2_addr_o,

    output wire[`WORD_BUS]     branch_addr_o,

// data to id_ex
    output wire                 inst_alu30_o,
    output wire [2:0]                funct3_o,

    output wire[`REG_DBUS]      pc_data_o,
    output wire[`REG_DBUS]      pc_plus_o,

    output wire[`IMM32_BUS]     imm_o,
    output wire[`REG_ABUS]      rd_addr_o,
    output wire[`REG_ABUS]      rs1_addr_o,
    output wire[`REG_ABUS]      rs2_addr_o,
    output wire[`REG_DBUS]      reg1_data_o,
    output wire[`REG_DBUS]      reg2_data_o,

    output [1:0] control_forward_o,
    output [1:0] control_jump_o,
    output [1:0] alu_op_o,
    output control_uart_o, //TODO
    output control_dmem_o,
    output [1:0] control_wr_mux_o,
    output control_csr_we_o,
    output branch_judge
    // output wire wb_en_o, //*
);

    // decocde
    wire[`REG_ABUS] inst_rd, inst_rs1, inst_rs2;
    wire[`FIELD_OPCODE] inst_opcode;

    assign  inst_rd     = inst_i[`FIELD_RD],
            inst_rs1    = inst_i[`FIELD_RS1],
            inst_rs2    = inst_i[`FIELD_RS2],
            inst_opcode = inst_i[`FIELD_OPCODE];

    assign  funct3_o        = inst_i[`FIELD_FUNCT3],
            inst_alu30_o    = inst_i[30]; 

    assign  rs1_addr_o   = inst_rs1,
            rs2_addr_o   = inst_rs2,
            rd_addr_o    = inst_rd;
        

    // next pc

    assign pc_data_o = pc_data_i;
    assign pc_plus_o = pc_data_i + 1;


    // reg_file

    assign  reg1_addr_o = inst_rs1,
            reg2_addr_o = inst_rs2;

    assign  reg1_data_o = reg1_data_i,
            reg2_data_o = reg2_data_i;    
    

    // control_unit
    wire control_branch;
    control_unit control (
        .opcode(inst_opcode),
        .control_forward(control_forward_o),
        .alu_op(alu_op_o),
        .control_jump(control_jump_o),
        .control_uart(control_uart_o),
        .control_dmem(control_dmem_o),
        .control_branch(control_branch),
        .control_wr_mux(control_wr_mux_o),
        .control_csr_we(control_csr_we_o));

    // imm_gen
    wire [31:0] branch_offset_o;
    imm_gen imm (
        .opcode_i(inst_i),
        .funct_i(inst_i[14:12]),
        .imm(imm_o),
        .branch_offset(branch_offset_o));
    
    branch_comp branch_comp(
        .is_branch(control_branch),
        .a(reg1_data_i),
        .b(reg2_data_i),
        .branch_type(funct3_o),
        .branch_judge(branch_judge)
    );

    assign branch_addr_o = branch_offset_o[31:2] + pc_data_o;

endmodule