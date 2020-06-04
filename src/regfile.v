module regfile(
    input wire      rst,
    input wire      clk,

    //写端口
    input wire      we,
    input wire[`RegAddrBus]      waddr,
    input wire[`RegBus]      wdata,
    
    //读端口1
    input wire[`RegAddrBus]     raddr1,
    input wire      re1,
    output wire[`RegBus]    rdata1,

    //读端口2
    input wire[`RegAddrBus]     raddr2,
    input wire      re2,
    output wire[`RegBus]    rdata2
);

    //寄存器定义
    reg[`RegBus]    regs[0: `RegNum-1];

    //写操作
    always @ (posedge clk) begin
        if (rst == `RstDisable) begin
            if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
                regs[waddr] <= wdata;
            end
        end
    end

    //TODO:读寄存器操作不改变状态，感觉不用读使能信号，写的过于复杂

    //读操作1 
    always @ (*) begin
        if (rst == `RstDisable) begin
            rdata1 <= `ZeroWord;
        end else if (raddr1 == `RegNumLog2'h0) begin
            rdata1 <= `ZeroWord;
        end else if ((raddr1 == waddr) && (we == `WriteEnable)
                        && (re1 == `ReadEnable)) begin
            rdata1 <= wdata;
        end else if (re1 == `ReadEnable) begin
            rdata1 <= reg[raddr1];
        end else begin
            rdata1 <= `ZeroWord;
        end
    end

    //读操作2
    always @ (*) begin
        if (rst == `RstDisable) begin
            rdata2 <= `ZeroWord;
        end else if (raddr2 == `RegNumLog2'h0) begin
            rdata2 <= `ZeroWord;
        end else if ((raddr2 == waddr) && (we == `WriteEnable)
                        && (re2 == `ReadEnable)) begin
            rdata2 <= wdata;
        end else if (re2 == `ReadEnable) begin
            rdata2 <= reg[raddr2];
        end else begin
            rdata2 <= `ZeroWord;
        end
    end
end module
            

