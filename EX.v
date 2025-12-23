// EX.v
`include "lib/defines.vh"
module EX(
    input wire clk,
    input wire rst,
    input wire [`StallBus-1:0] stall,

    input wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    
    // 转发输出
    output wire ex_we_o,
    output wire [4:0] ex_waddr_o,
    output wire [31:0] ex_wdata_o,

    output wire data_sram_en,
    output wire [3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    
    // 暂停请求
    output wire stallreq
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
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [31:0] rf_rdata1, rf_rdata2;

    assign {
        ex_pc,          // 148:117
        inst,           // 116:85
        alu_op,         // 84:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rf_rdata1,      // 63:32
        rf_rdata2       // 31:0
    } = id_to_ex_bus_r;

    // 指令译码（用于特殊指令处理）
    wire [5:0] opcode, func;
    wire [4:0] rs, rt, rd, sa;
    
    assign opcode = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign sa = inst[10:6];
    assign func = inst[5:0];
    
    // 立即数扩展
    wire [31:0] imm_sign_extend, imm_zero_extend, sa_zero_extend;
    
    assign imm_sign_extend = {{16{inst[15]}}, inst[15:0]};
    assign imm_zero_extend = {16'b0, inst[15:0]};
    assign sa_zero_extend = {27'b0, inst[10:6]};

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

    assign ex_result = alu_result;

    // 转发输出
    assign ex_we_o = rf_we;
    assign ex_waddr_o = rf_waddr;
    assign ex_wdata_o = ex_result;

    // 访存信号（暂不实现load/store）
    assign data_sram_en = data_ram_en;
    assign data_sram_wen = data_ram_wen;
    assign data_sram_addr = ex_result;
    assign data_sram_wdata = rf_rdata2;

    // EX到MEM的总线
    assign ex_to_mem_bus = {
        ex_pc,          // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result       // 31:0
    };

    // 乘法器
    wire [63:0] mul_result;
    wire mul_signed;
    wire inst_mult, inst_multu;
    
    assign inst_mult  = (opcode == 6'b000000) & (func == 6'b011000);
    assign inst_multu = (opcode == 6'b000000) & (func == 6'b011001);
    assign mul_signed = inst_mult ? 1'b1 : 1'b0;

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
    wire inst_div, inst_divu;
    wire div_ready_i;
    
    assign inst_div  = (opcode == 6'b000000) & (func == 6'b011010);
    assign inst_divu = (opcode == 6'b000000) & (func == 6'b011011);
    
    reg stallreq_for_div;
    assign stallreq = stallreq_for_div;

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

    always @ (*) begin
        if (rst) begin
            stallreq_for_div = `NoStop;
            div_opdata1_o = `ZeroWord;
            div_opdata2_o = `ZeroWord;
            div_start_o = `DivStop;
            signed_div_o = 1'b0;
        end
        else begin
            stallreq_for_div = `NoStop;
            div_opdata1_o = `ZeroWord;
            div_opdata2_o = `ZeroWord;
            div_start_o = `DivStop;
            signed_div_o = 1'b0;
            
            if (inst_div || inst_divu) begin
                if (div_ready_i == `DivResultNotReady) begin
                    div_opdata1_o = rf_rdata1;
                    div_opdata2_o = rf_rdata2;
                    div_start_o = `DivStart;
                    signed_div_o = inst_div ? 1'b1 : 1'b0;
                    stallreq_for_div = `Stop;
                end
                else if (div_ready_i == `DivResultReady) begin
                    div_opdata1_o = rf_rdata1;
                    div_opdata2_o = rf_rdata2;
                    div_start_o = `DivStop;
                    signed_div_o = inst_div ? 1'b1 : 1'b0;
                    stallreq_for_div = `NoStop;
                end
            end
        end
    end

endmodule