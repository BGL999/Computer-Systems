// MEM.v
`include "lib/defines.vh"
module MEM(
    input wire clk,
    input wire rst,
    input wire [`StallBus-1:0] stall,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [31:0] data_sram_rdata,

    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,
    
    // 数据转发输出
    output wire mem_we_o,
    output wire [4:0] mem_waddr_o,
    output wire [31:0] mem_wdata_o,
    
    // 调试信号
    output wire [31:0] mem_pc_o
);

    reg [`EX_TO_MEM_WD-1:0] ex_to_mem_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        else if (stall[3]==`Stop && stall[4]==`NoStop) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        else if (stall[3]==`NoStop) begin
            ex_to_mem_bus_r <= ex_to_mem_bus;
        end
    end

    // 总线分解
    wire [31:0] mem_pc;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire [`MEM_OP_BUS] mem_op;
    wire [`MEM_SIZE_BUS] mem_size;
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] ex_result;
    wire [31:0] store_data;

    assign {
        mem_pc,         // 106:75
        data_ram_en,    // 74
        data_ram_wen,   // 73:70
        mem_op,         // 69:68
        mem_size,       // 67:66
        sel_rf_res,     // 65
        rf_we,          // 64
        rf_waddr,       // 63:59
        ex_result,      // 58:27
        store_data      // 26:0
    } =  ex_to_mem_bus_r;

    assign mem_pc_o = mem_pc;

    // 访存数据处理
    wire [31:0] mem_result;
    reg [31:0] load_data;
    
    always @(*) begin
        case (mem_size)
            `MEM_SIZE_BYTE: begin
                case (ex_result[1:0])
                    2'b00: load_data = {{24{data_sram_rdata[7]}},  data_sram_rdata[7:0]};
                    2'b01: load_data = {{24{data_sram_rdata[15]}}, data_sram_rdata[15:8]};
                    2'b10: load_data = {{24{data_sram_rdata[23]}}, data_sram_rdata[23:16]};
                    2'b11: load_data = {{24{data_sram_rdata[31]}}, data_sram_rdata[31:24]};
                endcase
            end
            `MEM_SIZE_HALF: begin
                case (ex_result[1])
                    1'b0: load_data = {{16{data_sram_rdata[15]}}, data_sram_rdata[15:0]};
                    1'b1: load_data = {{16{data_sram_rdata[31]}}, data_sram_rdata[31:16]};
                endcase
            end
            `MEM_SIZE_WORD: begin
                load_data = data_sram_rdata;
            end
            default: load_data = `ZeroWord;
        endcase
    end
    
    // 无符号加载处理
    wire [31:0] mem_load_result;
    assign mem_load_result = (mem_size == `MEM_SIZE_BYTE && mem_op == `MEM_OP_LOAD && 
                             (ex_result[1:0] == 2'b00)) ? 
                             {24'b0, data_sram_rdata[7:0]} :
                            (mem_size == `MEM_SIZE_BYTE && mem_op == `MEM_OP_LOAD && 
                             (ex_result[1:0] == 2'b01)) ? 
                             {24'b0, data_sram_rdata[15:8]} :
                            (mem_size == `MEM_SIZE_BYTE && mem_op == `MEM_OP_LOAD && 
                             (ex_result[1:0] == 2'b10)) ? 
                             {24'b0, data_sram_rdata[23:16]} :
                            (mem_size == `MEM_SIZE_BYTE && mem_op == `MEM_OP_LOAD && 
                             (ex_result[1:0] == 2'b11)) ? 
                             {24'b0, data_sram_rdata[31:24]} :
                            (mem_size == `MEM_SIZE_HALF && mem_op == `MEM_OP_LOAD && 
                             ex_result[1] == 1'b0) ? 
                             {16'b0, data_sram_rdata[15:0]} :
                            (mem_size == `MEM_SIZE_HALF && mem_op == `MEM_OP_LOAD && 
                             ex_result[1] == 1'b1) ? 
                             {16'b0, data_sram_rdata[31:16]} :
                            load_data;

    assign mem_result = (mem_op == `MEM_OP_LOAD) ? mem_load_result : ex_result;

    // 转发输出
    assign mem_we_o = rf_we;
    assign mem_waddr_o = rf_waddr;
    assign mem_wdata_o = mem_result;

    // 写回数据选择
    wire [31:0] rf_wdata;
    assign rf_wdata = sel_rf_res ? mem_result : ex_result;

    // MEM到WB的总线
    assign mem_to_wb_bus = {
        mem_pc,     // 69:38
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata    // 31:0
    };

endmodule