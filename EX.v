// EX.v
`include "lib/defines.vh"
module EX(
    input wire clk,
    input wire rst,
    input wire [`StallBus-1:0] stall,

    input wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    
    // 数据转发输出
    output wire ex_we_o,
    output wire [4:0] ex_waddr_o,
    output wire [31:0] ex_wdata_o,
    
    // HI/LO控制输出
    output wire hi_we_o,
    output wire [31:0] hi_wdata_o,
    output wire lo_we_o,
    output wire [31:0] lo_wdata_o,
    output wire [1:0] mul_type_o,
    output wire [1:0] div_type_o,

    output wire data_sram_en,
    output wire [3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    
    // 暂停请求
    output wire stallreq,
    
    // 调试信号
    output wire [31:0] ex_pc_o
);

    reg [`ID_TO_EX_WD-1:0] id_to_ex_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        end
        else if (stall[2]==`Stop && stall[3]==`NoStop) begin
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        end
        else if (stall[2]==`NoStop) begin
            id_to_ex_bus_r <= id_to_ex_bus;
        end
    end

    // 总线分解
    wire [31:0] ex_pc, inst;
    wire [11:0] alu_op;
    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire [`MEM_OP_BUS] mem_op;
    wire [`MEM_SIZE_BUS] mem_size;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [31:0] rf_rdata1, rf_rdata2;

    assign {
        ex_pc,          // 159:128
        inst,           // 127:96
        alu_op,         // 95:84
        sel_alu_src1,   // 83:81
        sel_alu_src2,   // 80:77
        data_ram_en,    // 76
        data_ram_wen,   // 75:72
        mem_op,         // 71:70
        mem_size,       // 69:68
        rf_we,          // 67
        rf_waddr,       // 66:62
        sel_rf_res,     // 61
        rf_rdata1,      // 60:29
        rf_rdata2       // 28:0
    } = id_to_ex_bus_r;

    assign ex_pc_o = ex_pc;

    // 指令译码（用于特殊指令处理）
    wire [5:0] opcode = inst[31:26];
    wire [4:0] rs = inst[25:21];
    wire [4:0] rt = inst[20:16];
    wire [4:0] rd = inst[15:11];
    wire [4:0] sa = inst[10:6];
    wire [5:0] func = inst[5:0];
    wire [15:0] imm = inst[15:0];
    
    // 立即数扩展
    wire [31:0] imm_sign_extend, imm_zero_extend, sa_zero_extend;
    
    assign imm_sign_extend = {{16{imm[15]}}, imm};
    assign imm_zero_extend = {16'b0, imm};
    assign sa_zero_extend = {27'b0, sa};

    // ALU输入选择
    wire [31:0] alu_src1, alu_src2;
    wire [31:0] alu_result, ex_result;

    assign alu_src1 = sel_alu_src1[1] ? ex_pc :          // PC for jal/jalr
                      sel_alu_src1[2] ? sa_zero_extend : // sa for shift
                      rf_rdata1;                         // rs

    assign alu_src2 = sel_alu_src2[1] ? imm_sign_extend : // immediate
                      sel_alu_src2[2] ? 32'd8 :           // 8 for link
                      sel_alu_src2[3] ? imm_zero_extend : // zero-extend immediate
                      rf_rdata2;                          // rt
    
    // ALU实例化
    alu u_alu(
        .alu_control (alu_op     ),
        .alu_src1    (alu_src1   ),
        .alu_src2    (alu_src2   ),
        .alu_result  (alu_result )
    );

    // 乘除指令的处理
    wire inst_mult, inst_multu, inst_div, inst_divu;
    wire inst_mfhi, inst_mflo, inst_mthi, inst_mtlo;
    
    assign inst_mult  = (opcode == 6'b000000) && (func == 6'b011000);
    assign inst_multu = (opcode == 6'b000000) && (func == 6'b011001);
    assign inst_div   = (opcode == 6'b000000) && (func == 6'b011010);
    assign inst_divu  = (opcode == 6'b000000) && (func == 6'b011011);
    assign inst_mfhi  = (opcode == 6'b000000) && (func == 6'b010000);
    assign inst_mflo  = (opcode == 6'b000000) && (func == 6'b010010);
    assign inst_mthi  = (opcode == 6'b000000) && (func == 6'b010001);
    assign inst_mtlo  = (opcode == 6'b000000) && (func == 6'b010011);
    
    // 乘除类型输出
    assign mul_type_o = inst_mult  ? `MUL_TYPE_MULT :
                       inst_multu ? `MUL_TYPE_MULTU : `MUL_TYPE_NONE;
    assign div_type_o = inst_div   ? `DIV_TYPE_DIV :
                       inst_divu  ? `DIV_TYPE_DIVU : `DIV_TYPE_NONE;
    
    // HI/LO写使能和写数据
    assign hi_we_o = inst_mthi | inst_mult | inst_multu | inst_div | inst_divu;
    assign lo_we_o = inst_mtlo | inst_mult | inst_multu | inst_div | inst_divu;
    
    // 乘法器
    wire [63:0] mul_result;
    wire mul_signed = inst_mult ? 1'b1 : 1'b0;
    
    mul u_mul(
        .clk        (clk            ),
        .resetn     (~rst           ),
        .mul_signed (mul_signed     ),
        .ina        (rf_rdata1      ),
        .inb        (rf_rdata2      ),
        .result     (mul_result     )
    );
    
    // 除法器
    wire [63:0] div_result;
    wire div_ready_i;
    
    reg [31:0] div_opdata1_o;
    reg [31:0] div_opdata2_o;
    reg div_start_o;
    reg signed_div_o;
    
    div u_div(
        .rst          (rst          ),
        .clk          (clk          ),
        .signed_div_i (signed_div_o ),
        .opdata1_i    (div_opdata1_o),
        .opdata2_i    (div_opdata2_o),
        .start_i      (div_start_o  ),
        .annul_i      (1'b0         ),
        .result_o     (div_result   ),
        .ready_o      (div_ready_i  )
    );
    
    // 乘除暂停请求
    reg stallreq_for_muldiv;
    
    // HI/LO写数据选择
    wire [63:0] muldiv_result;
    assign muldiv_result = (inst_mult || inst_multu) ? mul_result : div_result;
    
    assign hi_wdata_o = inst_mthi ? rf_rdata1 : muldiv_result[63:32];
    assign lo_wdata_o = inst_mtlo ? rf_rdata1 : muldiv_result[31:0];
    
    // 乘除控制逻辑
    always @(*) begin
        div_start_o = `DivStop;
        signed_div_o = 1'b0;
        stallreq_for_muldiv = `NoStop;
        div_opdata1_o = `ZeroWord;
        div_opdata2_o = `ZeroWord;
        
        if (inst_div || inst_divu) begin
            if (div_ready_i == `DivResultNotReady) begin
                div_opdata1_o = rf_rdata1;
                div_opdata2_o = rf_rdata2;
                div_start_o = `DivStart;
                signed_div_o = inst_div ? 1'b1 : 1'b0;
                stallreq_for_muldiv = `Stop;
            end
        end
    end
    
    // mfhi/mflo指令的结果选择
    wire [31:0] mf_result;
    assign mf_result = inst_mfhi ? hi_wdata_o : 
                      inst_mflo ? lo_wdata_o : alu_result;
    
    // 最终EX结果选择
    assign ex_result = (inst_mfhi | inst_mflo) ? mf_result : alu_result;

    // 转发输出
    assign ex_we_o = rf_we & ~(inst_mult | inst_multu | inst_div | inst_divu | 
                              inst_mthi | inst_mtlo); // 乘除和mt指令不写通用寄存器
    assign ex_waddr_o = rf_waddr;
    assign ex_wdata_o = ex_result;

    // 访存信号
    assign data_sram_en = data_ram_en;
    assign data_sram_wen = data_ram_wen;
    assign data_sram_addr = alu_result;
    
    // 存储数据对齐
    assign data_sram_wdata = (mem_size == `MEM_SIZE_BYTE) ? {4{rf_rdata2[7:0]}} :
                            (mem_size == `MEM_SIZE_HALF) ? {2{rf_rdata2[15:0]}} :
                            rf_rdata2;

    // EX到MEM的总线
    assign ex_to_mem_bus = {
        ex_pc,          // 106:75
        data_ram_en,    // 74
        data_ram_wen,   // 73:70
        mem_op,         // 69:68
        mem_size,       // 67:66
        sel_rf_res,     // 65
        rf_we,          // 64
        rf_waddr,       // 63:59
        ex_result,      // 58:27
        rf_rdata2       // 26:0
    };

    // 暂停请求（乘除）
    assign stallreq = stallreq_for_muldiv;

endmodule