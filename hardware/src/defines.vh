`ifndef DEFINES
`define DEFINES

// data
`define WORD_WIDTH      32
`define WORD_BUS        31:0
`define HALF_WORD_WIDTH 16
`define HALF_WORD_BUS   15:0

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
`define BIOS_DBUS       31:0
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
`define ALUOP_ISJTYPE 2'b01
`define ALUOP_ADTYPE 2'b10
`define ALUOP_UTYPE  2'b11

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

`define ALUCTRL_ADD     4'b0000
`define ALUCTRL_SLL     4'b0001
`define ALUCTRL_SLT     4'b0010
`define ALUCTRL_SLTU    4'b0011
`define ALUCTRL_XOR     4'b0100
`define ALUCTRL_OR      4'b0110
`define ALUCTRL_AND     4'b0111
`define ALUCTRL_SRL     4'b0101

`define ALUCTRL_SUB     4'b1000
`define ALUCTRL_SRA     4'b1101
`define ALUCTRL_SLLI    4'b0101
`define ALUCTRL_SRAI    4'b1010

//-----judgement of forwarding unit and mux
`define REG1_MUX_REG    2'b01
`define REG1_MUX_WB     2'b00
`define REG1_MUX_PC     2'b11
`define REG2_MUX_REG    2'b01 
`define REG2_MUX_WB     2'b00
`define REG2_MUX_IMM    2'b11

`define FORWARD_PC1     2'b01
`define FORWARD_REG     2'b00
`define FORWARD_STORE   2'b10
`define FORWARD_IMM     2'b11

//----judgement of load bit type
`define DMEM_LW         3'b001 
`define DMEM_LH         3'b010 
`define DMEM_LB         3'b101
`define DMEM_LHU        3'b011 
`define DMEM_LBU        3'b100
//----judgement of store bit type
`define DMEM_SW         3'b001
`define DMEM_SH         3'b010 
`define DMEM_SB         3'b100

//------branch and jal and jalr jump unit signal

`define BGE 3'b101 
`define BEQ 3'b000 
`define BGEU 3'b111 
`define BLT 3'b100 
`define BLTU 3'b110 
`define BNE 3'b001

//-------define of conv2D-----------------//
`define CONV_WRITE 32'h80000040
`define CONV_READ 32'h80000044
`define CONV_FEATURE 32'h80000048
`define CONV_WEIGHT 32'h8000004c
`define CONV_INPUT 32'h80000050
`define CONV_OUTPUT 32'h80000054

`define CONV_RESET          32'h80000018
`define CONV_START          32'h80000040
`define CONV_STATUS         32'h80000044
`define CONV_FM_DIM         32'h80000048
`define CONV_WEIGHT_OFF     32'h8000004c
`define CONV_INPUT_FM       32'h80000050
`define CONV_OUTPUT_FM      32'h80000054

`endif
