`include "../defines.vh"

/*
*   TODO:
*   id_ex pipeline register file, connect to ex stage
*   @OUTPUT:
*   wb_addr
*   imm
*   alu_op*
*   //control signal*
*   reg1_data
*   reg2_data
*   //write_back enable*
*   
*/
module id_ex (
    input wire rst,
    input wire clk,

    input wire[`REG_DBUS]   reg1_data_i,
    input wire[`REG_DBUS]   reg2_data_i,
    input wire[`REG_ABUS]   wb_addr_i,
    input wire[`IMM_BUS]    imm_i,

    output wire[`REG_DBUS]  reg1_data_o,
    output wire[`REG_DBUS]  reg2_data_o,
    output wire[`REG_ABUS]  wb_addr_o,
    output wire[`IMM_BUS]   imm_o

);
    wire[`REG_DBUS] reg_data_i [0:1];
    wire[`REG_DBUS] reg_data_o [0:1];

    assign  reg_data_i[0] = reg1_data_i,
            reg_data_i[1] = reg2_data_i;
    
    assign  reg1_data_o = reg_data_o[0],
            reg2_data_o = reg_data_o[1];

    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin:
        reg_data_store
            REGISTER_R #(.N(`REG_DWIDTH)) reg_data(
                .q(reg_data_o[i]),
                .clk(clk),
                .rst(rst),
                .d(reg_data_i[i])
            );
        end
    endgenerate


    REGISTER_R #(.N(`REG_AWIDTH)) reg_wb_addr(
        .q(wb_addr_o),
        .clk(clk),
        .rst(rst),
        .d(wb_addr_i)
    );

    REGISTER_R #(.N(`IMM_WIDTH)) imm_data(
        .q(imm_o),
        .clk(clk),
        .rst(rst),
        .d(imm_i)
    );



endmodule // id_ex