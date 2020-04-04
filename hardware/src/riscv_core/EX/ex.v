/**
* execution stage
*   @OUTPUT:
*   
* 
*
*/
`include "../defines.vh"
`include "../mux.v"

module ex (
    input wire[`REG_DBUS]       reg1_data_i,
    input wire[`REG_DBUS]       reg2_data_i,
    input wire[`REG_ABUS]       wb_addr_i,
    input wire[`IMM32_BUS]      imm_i,
    input wire[2:0]             funct3_i,
    input wire                  inst_alu30_i,

    input wire                  alu_src1_sel_i,
    input wire                  alu_src2_sel_i,
    input wire                  mem_read_i,
    input wire                  mem_write_i,
    input wire                  wb_enable_i,
    //input pc_sel

    output wire[`WORD_BUS]      alu_result_o
);
    wire [`WORD_BUS] alu_src1, alu_src2;

    mux_reg1 src1 (


    );

    mux_reg2 src2 (

    );

    // alu_control
    wire [3:0] alu_ctrl;
    alu_control alu_control0 (
        .inst_alu(),
        .inst_alu30(),
        .aluOp(),
        .aluCtrl(alu_ctrl)
    );

    // alu


endmodule // ex 