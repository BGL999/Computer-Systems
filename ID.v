// ID.v
`include "lib/defines.vh"
module ID(
    input wire clk,
    input wire rst,
    input wire [`StallBus-1:0] stall,
    
    output reg stallreq,

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    input wire [31:0] inst_sram_rdata,

    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,
    
    // 数据转发输入
    input wire ex_we_i,
    input wire [4:0] ex_waddr_i,
    input wire [31:0] ex_wdata_i,
    
    input wire mem_we_i,
    input wire [4:0] mem_waddr_i,
    input wire [31:0] mem_wdata_i,
    
    // HI/LO寄存器值
    input wire [31:0] hi_value_i,
    input wire [31:0] lo_value_i,

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`BR_WD-1:0] br_bus,
    
    // 调试信号
    output wire [31:0] id_pc_o
);

    reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;
    wire [31:0] inst;
    wire [31:0] id_pc;
    wire ce;

    wire wb_rf_we;
    wire [4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;

    always @ (posedge clk) begin
        if (rst) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;        
        end
        else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
        end
        else if (stall[1]==`NoStop) begin
            if_to_id_bus_r <= if_to_id_bus;
        end
    end
    
    assign inst = inst_sram_rdata;
    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;
    assign id_pc_o = id_pc;
    
    assign {
        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata
    } = wb_to_rf_bus;

    // 指令译码
    wire [5:0] opcode = inst[31:26];
    wire [4:0] rs = inst[25:21];
    wire [4:0] rt = inst[20:16];
    wire [4:0] rd = inst[15:11];
    wire [4:0] sa = inst[10:6];
    wire [5:0] func = inst[5:0];
    wire [15:0] imm = inst[15:0];
    wire [25:0] instr_index = inst[25:0];
    wire [4:0] base = inst[25:21];
    wire [15:0] offset = inst[15:0];

    // 指令定义
    wire inst_ori, inst_lui, inst_addiu, inst_beq, inst_bne;
    wire inst_add, inst_addu, inst_sub, inst_subu;
    wire inst_slt, inst_sltu, inst_and, inst_or, inst_xor, inst_nor;
    wire inst_sll, inst_srl, inst_sra;
    wire inst_jr, inst_jalr, inst_j, inst_jal;
    wire inst_slti, inst_sltiu, inst_andi, inst_xori;
    wire inst_mult, inst_multu, inst_div, inst_divu;
    wire inst_mfhi, inst_mflo, inst_mthi, inst_mtlo;
    wire inst_lw, inst_sw, inst_lh, inst_lhu, inst_lb, inst_lbu, inst_sh, inst_sb;
    
    // R-type指令判断
    wire inst_rtype = (opcode == 6'b000000);
    assign inst_add  = inst_rtype & (func == 6'b100000);
    assign inst_addu = inst_rtype & (func == 6'b100001);
    assign inst_sub  = inst_rtype & (func == 6'b100010);
    assign inst_subu = inst_rtype & (func == 6'b100011);
    assign inst_slt  = inst_rtype & (func == 6'b101010);
    assign inst_sltu = inst_rtype & (func == 6'b101011);
    assign inst_and  = inst_rtype & (func == 6'b100100);
    assign inst_or   = inst_rtype & (func == 6'b100101);
    assign inst_xor  = inst_rtype & (func == 6'b100110);
    assign inst_nor  = inst_rtype & (func == 6'b100111);
    assign inst_sll  = inst_rtype & (func == 6'b000000);
    assign inst_srl  = inst_rtype & (func == 6'b000010);
    assign inst_sra  = inst_rtype & (func == 6'b000011);
    assign inst_jr   = inst_rtype & (func == 6'b001000);
    assign inst_jalr = inst_rtype & (func == 6'b001001);
    assign inst_mult  = inst_rtype & (func == 6'b011000);
    assign inst_multu = inst_rtype & (func == 6'b011001);
    assign inst_div   = inst_rtype & (func == 6'b011010);
    assign inst_divu  = inst_rtype & (func == 6'b011011);
    assign inst_mfhi  = inst_rtype & (func == 6'b010000);
    assign inst_mflo  = inst_rtype & (func == 6'b010010);
    assign inst_mthi  = inst_rtype & (func == 6'b010001);
    assign inst_mtlo  = inst_rtype & (func == 6'b010011);
    
    // I-type指令
    assign inst_ori   = (opcode == 6'b001101);
    assign inst_lui   = (opcode == 6'b001111);
    assign inst_addiu = (opcode == 6'b001001);
    assign inst_beq   = (opcode == 6'b000100);
    assign inst_bne   = (opcode == 6'b000101);
    assign inst_slti  = (opcode == 6'b001010);
    assign inst_sltiu = (opcode == 6'b001011);
    assign inst_andi  = (opcode == 6'b001100);
    assign inst_xori  = (opcode == 6'b001110);
    
    // 访存指令
    assign inst_lw   = (opcode == 6'b100011);
    assign inst_sw   = (opcode == 6'b101011);
    assign inst_lh   = (opcode == 6'b100001);
    assign inst_lhu  = (opcode == 6'b100101);
    assign inst_lb   = (opcode == 6'b100000);
    assign inst_lbu  = (opcode == 6'b100100);
    assign inst_sh   = (opcode == 6'b101001);
    assign inst_sb   = (opcode == 6'b101000);
    
    // J-type指令
    assign inst_j    = (opcode == 6'b000010);
    assign inst_jal  = (opcode == 6'b000011);

    // 寄存器文件
    wire [31:0] rdata1_raw, rdata2_raw;
    reg [31:0] rdata1, rdata2;

    regfile u_regfile(
        .clk    (clk          ),
        .raddr1 (rs           ),
        .rdata1 (rdata1_raw   ),
        .raddr2 (rt           ),
        .rdata2 (rdata2_raw   ),
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  )
    );
    
    // 数据转发逻辑（组合逻辑）
    always @(*) begin
        // 转发rs数据（优先级：EX > MEM > WB > RAW）
        case ({ex_we_i && ex_waddr_i != 5'b0 && ex_waddr_i == rs,
               mem_we_i && mem_waddr_i != 5'b0 && mem_waddr_i == rs,
               wb_rf_we && wb_rf_waddr != 5'b0 && wb_rf_waddr == rs})
            3'b100, 3'b101, 3'b110, 3'b111: rdata1 = ex_wdata_i;
            3'b010, 3'b011: rdata1 = mem_wdata_i;
            3'b001: rdata1 = wb_rf_wdata;
            default: rdata1 = rdata1_raw;
        endcase
        
        // 转发rt数据
        case ({ex_we_i && ex_waddr_i != 5'b0 && ex_waddr_i == rt,
               mem_we_i && mem_waddr_i != 5'b0 && mem_waddr_i == rt,
               wb_rf_we && wb_rf_waddr != 5'b0 && wb_rf_waddr == rt})
            3'b100, 3'b101, 3'b110, 3'b111: rdata2 = ex_wdata_i;
            3'b010, 3'b011: rdata2 = mem_wdata_i;
            3'b001: rdata2 = wb_rf_wdata;
            default: rdata2 = rdata2_raw;
        endcase
    end

    // ALU源操作数1选择
    wire [2:0] sel_alu_src1;
    assign sel_alu_src1[0] = inst_ori | inst_addiu | inst_add | inst_addu | 
                           inst_sub | inst_subu | inst_slt | inst_sltu |
                           inst_and | inst_or | inst_xor | inst_nor |
                           inst_slti | inst_sltiu | inst_andi | inst_xori |
                           inst_mult | inst_multu | inst_div | inst_divu |
                           inst_mthi | inst_mtlo | inst_lw | inst_sw |
                           inst_lh | inst_lhu | inst_lb | inst_lbu |
                           inst_sh | inst_sb;
    
    assign sel_alu_src1[1] = inst_jal | inst_jalr;  // PC for link
    
    assign sel_alu_src1[2] = inst_sll | inst_srl | inst_sra;  // sa for shift

    // ALU源操作数2选择
    wire [3:0] sel_alu_src2;
    assign sel_alu_src2[0] = inst_add | inst_addu | inst_sub | inst_subu |
                           inst_slt | inst_sltu | inst_and | inst_or |
                           inst_xor | inst_nor | inst_sll | inst_srl |
                           inst_sra | inst_mult | inst_multu | 
                           inst_div | inst_divu | inst_mfhi | inst_mflo |
                           inst_mthi | inst_mtlo;
    
    assign sel_alu_src2[1] = inst_addiu | inst_lui | inst_slti | inst_sltiu |
                           inst_andi | inst_ori | inst_xori | 
                           inst_lw | inst_sw | inst_lh | inst_lhu | 
                           inst_lb | inst_lbu | inst_sh | inst_sb;  // 立即数
    
    assign sel_alu_src2[2] = inst_jal | inst_jalr;  // 32'd8 for link
    
    assign sel_alu_src2[3] = 1'b0;  // 保留

    // ALU操作控制
    wire op_add, op_sub, op_slt, op_sltu;
    wire op_and, op_nor, op_or, op_xor;
    wire op_sll, op_srl, op_sra, op_lui;
    
    assign op_add  = inst_addiu | inst_add | inst_addu | inst_lw | inst_sw |
                    inst_lh | inst_lhu | inst_lb | inst_lbu | inst_sh | inst_sb;
    assign op_sub  = inst_sub | inst_subu;
    assign op_slt  = inst_slt | inst_slti;
    assign op_sltu = inst_sltu | inst_sltiu;
    assign op_and  = inst_and | inst_andi;
    assign op_nor  = inst_nor;
    assign op_or   = inst_or | inst_ori;
    assign op_xor  = inst_xor | inst_xori;
    assign op_sll  = inst_sll;
    assign op_srl  = inst_srl;
    assign op_sra  = inst_sra;
    assign op_lui  = inst_lui;

    wire [11:0] alu_op;
    assign alu_op = {op_add, op_sub, op_slt, op_sltu,
                     op_and, op_nor, op_or, op_xor,
                     op_sll, op_srl, op_sra, op_lui};

    // 访存控制信号
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire [`MEM_OP_BUS] mem_op;
    wire [`MEM_SIZE_BUS] mem_size;
    
    assign data_ram_en = inst_lw | inst_sw | inst_lh | inst_lhu | 
                        inst_lb | inst_lbu | inst_sh | inst_sb;
    
    assign mem_op = (inst_lw | inst_lh | inst_lhu | inst_lb | inst_lbu) ? `MEM_OP_LOAD :
                   (inst_sw | inst_sh | inst_sb) ? `MEM_OP_STORE : `MEM_OP_NONE;
    
    assign mem_size = (inst_lw | inst_sw) ? `MEM_SIZE_WORD :
                     (inst_lh | inst_lhu | inst_sh) ? `MEM_SIZE_HALF : `MEM_SIZE_BYTE;
    
    // 写使能
    assign data_ram_wen = inst_sw ? 4'b1111 :
                         inst_sh ? (rdata1[1] ? 4'b1100 : 4'b0011) :
                         inst_sb ? (rdata1[1:0] == 2'b00 ? 4'b0001 :
                                   rdata1[1:0] == 2'b01 ? 4'b0010 :
                                   rdata1[1:0] == 2'b10 ? 4'b0100 : 4'b1000) : 4'b0000;

    // 寄存器堆写使能
    wire rf_we;
    assign rf_we = inst_ori | inst_lui | inst_addiu | inst_add | inst_addu |
                  inst_sub | inst_subu | inst_slt | inst_sltu | inst_and |
                  inst_or | inst_xor | inst_nor | inst_sll | inst_srl |
                  inst_sra | inst_slti | inst_sltiu | inst_andi | inst_xori |
                  inst_jal | inst_jalr | inst_mfhi | inst_mflo |
                  inst_lw | inst_lh | inst_lhu | inst_lb | inst_lbu;

    // 寄存器堆目标地址选择
    wire [2:0] sel_rf_dst;
    assign sel_rf_dst[0] = inst_add | inst_addu | inst_sub | inst_subu |
                          inst_slt | inst_sltu | inst_and | inst_or |
                          inst_xor | inst_nor | inst_sll | inst_srl |
                          inst_sra | inst_jalr | inst_mfhi | inst_mflo;  // rd
    
    assign sel_rf_dst[1] = inst_ori | inst_lui | inst_addiu | inst_slti |
                          inst_sltiu | inst_andi | inst_xori |
                          inst_lw | inst_lh | inst_lhu | inst_lb | inst_lbu;  // rt
    
    assign sel_rf_dst[2] = inst_jal;  // r31

    wire [4:0] rf_waddr;
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd 
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 5'd31;

    // 写回数据选择
    wire sel_rf_res;  // 0 from alu, 1 from mem
    assign sel_rf_res = inst_lw | inst_lh | inst_lhu | inst_lb | inst_lbu;

    // ID到EX的总线
    assign id_to_ex_bus = {
        id_pc,          // 159:128
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
        rdata1,         // 60:29
        rdata2          // 28:0
    };

    // 分支逻辑
    wire br_e;
    wire [31:0] br_addr;
    wire rs_eq_rt, rs_ne_rt;
    wire [31:0] pc_plus_4, pc_plus_8;
    
    assign pc_plus_4 = id_pc + 32'h4;
    assign pc_plus_8 = id_pc + 32'h8;

    // 使用转发后的数据进行比较
    assign rs_eq_rt = (rdata1 == rdata2);
    assign rs_ne_rt = (rdata1 != rdata2);

    // 分支地址计算
    wire [31:0] branch_target;
    assign branch_target = pc_plus_4 + {{14{imm[15]}}, imm, 2'b0};
    
    // 跳转地址计算
    wire [31:0] jump_target;
    assign jump_target = {pc_plus_4[31:28], instr_index, 2'b0};

    // 分支判断
    assign br_e = (inst_beq & rs_eq_rt) | (inst_bne & rs_ne_rt) | 
                  inst_j | inst_jal | inst_jr | inst_jalr;
    
    assign br_addr = inst_jr | inst_jalr ? rdata1 :
                     inst_j | inst_jal ? jump_target :
                     branch_target;

    assign br_bus = {
        br_e,
        br_addr
    };

    // load-use冒险检测
    reg load_use_hazard;
    wire ex_mem_read;
    
    // 假设EX阶段有访存指令（简化）
    always @(*) begin
        load_use_hazard = 1'b0;
        // 简化的检测逻辑，实际需要更复杂的判断
        if ((inst_lw | inst_lh | inst_lhu | inst_lb | inst_lbu) && 
            ((ex_waddr_i == rs) || (ex_waddr_i == rt))) begin
            load_use_hazard = 1'b1;
        end
    end
    
    assign stallreq = load_use_hazard;

endmodule