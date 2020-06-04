module pc_reg(
    input       wire        clk,
    input       wire        rst,
    output      wire[`InstAddrBus]  pc,
    output      wire        ce
);
    always @ (posedge clk)  begin
        if (rst == `RstEnable)
            ce <=   `ChipDisable;
        else
            ce <=   `ChipEnable;
    end

    always @ (posedge clk)  begin
        if (ce == `ChipDisable) //TODO:ce取值是更改之后，或者更改之前
            pc <= `ZeroWord;
        else
            pc <=  pc + 4'h4;
    end
endmodule
