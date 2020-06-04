//********************************全局宏定义***************************
`define RstEnable   1'b1
`define RstUnable   1'b0
`define ZeroWord    32'h00000000
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable  1'b1
`define ReadDisable 1'b0
`define AluOpBus    7:0     //ALUop-bus width
`define AluSelBus   2:0     //ALUsel-bus width
`define InstValid   1'b0    
`define InstInvalid 1'b1
`define True_v      1'b1    //logic-true
`define False_v     1'b0
`define ChipEnable  1'b1    
`define ChipDisable 1'b0

//********************************指令相关宏****************************
`define EXE_ORI     6'b001101
`define EXE_NOP     6'b000000

//AluOp
`define EXE_OR_OP   8'b00100101
`define EXE_NOP_OP  8'b00000000

//AluSel
`define EXE_RES_LOGIC   3'b001
`define EXE_RES_NOP     3'b000

//******************************ROM相关宏******************************
`define InstAddrBus     31:0    //ROM地址总线宽度
`define InstBus         31:0    //ROM数据总线宽度
`define InstMemNum      131071  //ROM实际大小128kb
`define InstMemNumLog2  17      //ROM实际使用的地址线宽度

//******************************RegFile相关宏
`define RegAddrBus      4:0     //RegFile地址总线宽度
`define RegBus          31:0    //RegFile模块的数据总线宽度
`define RegWidth        32      //Reg-32位宽
`define DoubleRegWidth  64      
`define DoubleRegBus    63:0
`define RegNum          32
`define RegNumLog2      5       //寻址通用寄存器使用的地址位数
`define NOPRegAddr      5'b00000