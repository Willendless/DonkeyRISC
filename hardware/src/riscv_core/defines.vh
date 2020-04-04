`ifndef DEFINES
`define DEFINES

// inst field
`define INST_WIDTH      32
`define INST_BUS        31:0

`define FIELD_RD        11:7
`define FIELD_RS1       19:15
`define FIELD_RS2       24:20
`define FIELD_OPCODE    6:0
`define FIELD_OPCODE_5  6:2
`define FIELD_FUNCT3    14:12
`define FIELD_FUNCT7    31:25

// immediate number
`define IMM32_WIDTH       32
`define IMM32_BUS         31:0

// BIOS
`define BIOS_AWIDTH     12
`define BIOS_DWIDTH     32
`define BIOS_ABUS       11:0
`define BIOS_DWIDTH     31:0
// REGFILE
`define REG_AWIDTH      5 
`define REG_DWIDTH      32
`define REG_ABUS        4:0
`define REG_DBUS        31:0
// IMEM
`define IMEM_AWIDTH     14
`define IMEM_DWIDTH     32
`define IMEM_ABUS       13:0
`define IMEM_DBUS       31:0
// DMEM
`define DMEM_AWIDTH     32
`define DMEM_DWIDTH     32
`define DMEM_ABUS       31:0
`define DMEM_DBUS       31:0

`define ALUOP_RTYPE 2'b00
`define ALUOP_ISTYPE 2'b01
`define ALUOP_OTHER 2'b10

//load and store function are all defined as add function

`define ALUCTRL_LB      4'b0000
`define ALUCTRL_LH      4'b0000
`define ALUCTRL_LW      4'b0000
`define ALUCTRL_LBU     4'b0000
`define ALUCTRL_LHU     4'b0000
`define ALUCTRL_SB      4'b0000
`define ALUCTRL_SH      4'b0000
`define ALUCTRL_SW      4'b0000

//r_type function define

`define ALUCTRL_AD      4'b0000
`define ALUCTRL_SLL     4'b0001
`define ALUCTRL_SLT     4'b0010
`define ALUCTRL_SLTU    4'b0011
`define ALUCTRL_XOR     4'b0100
`define ALUCTRL_OR      4'b0110
`define ALUCTRL_AND     4'b0111
`define ALUCTRL_SRL     4'b0101

`define ALUCTRL_SUB     4'b1000
`define ALUCTRL_SRA     4'b1101

`endif
