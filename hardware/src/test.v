`include "EECS151.v"

module test (
    input clk,
    input[4:0] rf_wa,
    input[31:0] rf_wd,
    input[3:0] rf_we,
    
    input[4:0] rf_wa1,
    input[4:0] rf_wa2,
    output[31:0] rf_rd1,
    output[31:0] rf_rd2
);

    REGFILE_1W2R # (
        .AWIDTH(5),
        .DWIDTH(32),
        .DEPTH(32)
    ) rf (
        .d0(rf_wd),     // input
        .addr0(rf_wa), // input
        .we0(rf_we),    // input
        .q1(rf_rd1),    // output
        .addr1(rf_ra1), // input
        .q2(rf_rd2),    // output
        .addr2(rf_ra2), // input
        .clk(clk));
endmodule // test 