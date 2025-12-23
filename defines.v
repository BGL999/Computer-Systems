// lib/defines.vh
// 请备份原文件，然后替换为以下内容

`ifndef MYCPU_DEFINES_VH
`define MYCPU_DEFINES_VH

// 常量定义
`define RstEnable           1'b1
`define RstDisable          1'b0
`define ZeroWord            32'h00000000
`define WriteEnable         1'b1
`define WriteDisable        1'b0
`define ReadEnable          1'b1
`define ReadDisable         1'b0
`define AluOpBus            11:0
`define AluSelBus           2:0
`define InstValid           1'b0
`define InstInvalid         1'b1
`define Stop                1'b1
`define NoStop              1'b0
`define Branch              1'b1
`define NotBranch           1'b0
`define InterruptAssert     1'b1
`define InterruptNotAssert  1'b0
`define InDelaySlot         1'b1
`define NotInDelaySlot      1'b0
`define ChipEnable          1'b1
`define ChipDisable         1'b0

// 除法器控制
`define DivStop             1'b0
`define DivStart            1'b1
`define DivResultNotReady   1'b0
`define DivResultReady      1'b1

// 总线宽度定义
`define InstAddrBus         31:0
`define InstBus             31:0
`define InstMemNum          131071
`define InstMemNumLog2      17
`define DataAddrBus         31:0
`define DataBus             31:0
`define DataMemNum          131071
`define DataMemNumLog2      17
`define ByteWidth           7:0

`define RegAddrBus          4:0
`define RegBus              31:0
`define RegWidth            32
`define DoubleRegWidth      64
`define DoubleRegBus        63:0
`define RegNum              32
`define RegNumLog2          5
`define NOPRegAddr          5'b00000

// 流水线总线宽度
`define IF_TO_ID_WD         33      // ce(1) + pc(32)
`define ID_TO_EX_WD         159     // 具体见ID模块拼接
`define EX_TO_MEM_WD        76      // 具体见EX模块拼接  
`define MEM_TO_WB_WD        70      // 具体见MEM模块拼接
`define WB_TO_RF_WD         70      // we(1) + waddr(5) + wdata(32)

// 分支总线
`define BR_WD               33      // br_e(1) + br_addr(32)

// 暂停总线
`define StallBus            5:0

// 调试信号
`define DebugWBDataBus      31:0
`define DebugWBAddrBus      4:0

// ALU操作定义
`define EXE_ALU_ADD         12'b100000000000
`define EXE_ALU_SUB         12'b010000000000
`define EXE_ALU_SLT         12'b001000000000
`define EXE_ALU_SLTU        12'b000100000000
`define EXE_ALU_AND         12'b000010000000
`define EXE_ALU_NOR         12'b000001000000
`define EXE_ALU_OR          12'b000000100000
`define EXE_ALU_XOR         12'b000000010000
`define EXE_ALU_SLL         12'b000000001000
`define EXE_ALU_SRL         12'b000000000100
`define EXE_ALU_SRA         12'b000000000010
`define EXE_ALU_LUI         12'b000000000001

// 数据源选择
`define EXE_RES_NOP         3'b000
`define EXE_RES_LOGIC       3'b001
`define EXE_RES_SHIFT       3'b010
`define EXE_RES_MOVE        3'b011
`define EXE_RES_ARITH       3'b100
`define EXE_RES_JUMP_BRANCH 3'b101
`define EXE_RES_LOAD_STORE  3'b110
`define EXE_RES_MULT        3'b111

`endif