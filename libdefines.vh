// lib/defines.vh
`ifndef MYCPU_DEFINES_VH
`define MYCPU_DEFINES_VH

// 基本常量
`define ZeroWord            32'h00000000
`define WriteEnable         1'b1
`define WriteDisable        1'b0
`define ReadEnable          1'b1
`define ReadDisable         1'b0
`define ChipEnable          1'b1
`define ChipDisable         1'b0

// 暂停控制
`define Stop                1'b1
`define NoStop              1'b0

// 分支控制
`define Branch              1'b1
`define NotBranch           1'b0

// 除法器控制
`define DivStop             1'b0
`define DivStart            1'b1
`define DivResultNotReady   1'b0
`define DivResultReady      1'b1

// 访存控制
`define MemOpBus            1:0
`define MemOpRead           2'b01
`define MemOpWrite          2'b10

// 总线宽度定义
`define RegAddrBus          4:0
`define RegBus              31:0
`define DoubleRegBus        63:0
`define RegNum              32
`define InstAddrBus         31:0
`define InstBus             31:0
`define DataAddrBus         31:0
`define DataBus             31:0

// 流水线总线宽度（已调整以匹配实际需求）
`define IF_TO_ID_WD         33      // ce(1) + pc(32)
`define ID_TO_EX_WD         160     // pc(32)+inst(32)+alu_op(12)+sel_alu_src1(3)+sel_alu_src2(4)+data_ram_en(1)+data_ram_wen(4)+rf_we(1)+rf_waddr(5)+sel_rf_res(1)+rdata1(32)+rdata2(32)
`define EX_TO_MEM_WD        107     // pc(32)+data_ram_en(1)+data_ram_wen(4)+sel_rf_res(1)+rf_we(1)+rf_waddr(5)+ex_result(32)+mem_op(2)+mem_size(2)+rdata2(32)
`define MEM_TO_WB_WD        70      // pc(32)+rf_we(1)+rf_waddr(5)+rf_wdata(32)
`define WB_TO_RF_WD         38      // rf_we(1)+rf_waddr(5)+rf_wdata(32)

// 分支总线
`define BR_WD               33      // br_e(1) + br_addr(32)

// 暂停总线
`define StallBus            6

// ALU操作码（12位）
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

// 访存类型
`define MEM_OP_BUS          1:0
`define MEM_OP_NONE         2'b00
`define MEM_OP_LOAD         2'b01
`define MEM_OP_STORE        2'b10

// 访存大小
`define MEM_SIZE_BUS        1:0
`define MEM_SIZE_BYTE       2'b00
`define MEM_SIZE_HALF       2'b01
`define MEM_SIZE_WORD       2'b10

// 乘除操作类型
`define MUL_TYPE_NONE       2'b00
`define MUL_TYPE_MULT       2'b01
`define MUL_TYPE_MULTU      2'b10

`define DIV_TYPE_NONE       2'b00
`define DIV_TYPE_DIV        2'b01
`define DIV_TYPE_DIVU       2'b10

// 调试信号
`define DebugWBDataBus      31:0
`define DebugWBAddrBus      4:0

// 寄存器编号
`define REG_AT              5'd1    // $1
`define REG_V0             5'd2    // $2-$3
`define REG_A0             5'd4    // $4-$7
`define REG_T0             5'd8    // $8-$15
`define REG_S0             5'd16   // $16-$23
`define REG_T8             5'd24   // $24-$25
`define REG_K0             5'd26   // $26-$27
`define REG_GP             5'd28   // $28
`define REG_SP             5'd29   // $29
`define REG_FP             5'd30   // $30
`define REG_RA             5'd31   // $31

// 状态定义
`define STATE_IDLE          3'b000
`define STATE_FETCH         3'b001
`define STATE_DECODE        3'b010
`define STATE_EXECUTE       3'b011
`define STATE_MEMORY        3'b100
`define STATE_WRITEBACK     3'b101

`endif