// IF.v
`include "lib/defines.vh"
module IF(
    input wire clk,
    input wire rst,
    input wire [`StallBus-1:0] stall,

    input wire [`BR_WD-1:0] br_bus,

    output wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    output wire inst_sram_en,
    output wire [3:0] inst_sram_wen,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    
    // 调试信号
    output wire [31:0] if_pc_o
);

    reg [31:0] pc_reg;
    reg [31:0] pc_next;
    reg ce_reg;
    
    wire br_e;
    wire [31:0] br_addr;
    wire [31:0] pc_plus_4;
    wire [31:0] pc_plus_8;

    assign {
        br_e,
        br_addr
    } = br_bus;

    assign pc_plus_4 = pc_reg + 32'h4;
    assign pc_plus_8 = pc_reg + 32'h8;
    assign if_pc_o = pc_reg;

    // 下一个PC计算
    always @(*) begin
        if (rst) begin
            pc_next = 32'hbfbf_fffc;  // 启动地址
        end
        else if (br_e) begin
            pc_next = br_addr;        // 分支跳转
        end
        else begin
            pc_next = pc_plus_4;      // 顺序执行
        end
    end

    // PC寄存器更新
    always @(posedge clk) begin
        if (rst) begin
            pc_reg <= 32'hbfbf_fffc;
        end
        else if (stall[0]==`NoStop) begin
            pc_reg <= pc_next;
        end
    end

    // 使能寄存器
    always @(posedge clk) begin
        if (rst) begin
            ce_reg <= 1'b0;
        end
        else if (stall[0]==`NoStop) begin
            ce_reg <= 1'b1;
        end
    end

    // 指令存储器接口
    assign inst_sram_en = ce_reg && (stall[0]==`NoStop);
    assign inst_sram_wen = 4'b0;
    assign inst_sram_addr = pc_reg;
    assign inst_sram_wdata = 32'b0;
    
    // IF到ID的总线
    assign if_to_id_bus = {
        ce_reg,    // 指令有效
        pc_reg     // 当前PC
    };

endmodule