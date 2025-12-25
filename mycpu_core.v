// mycpu_core.v
`include "lib/defines.vh"
module mycpu_core(
    input wire clk,
    input wire rst,
    input wire [5:0] int,

    output wire inst_sram_en,
    output wire [3:0] inst_sram_wen,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input wire [31:0] inst_sram_rdata,

    output wire data_sram_en,
    output wire [3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input wire [31:0] data_sram_rdata,

    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_wen,
    output wire [4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

    // 流水线总线
    wire [`IF_TO_ID_WD-1:0] if_to_id_bus;
    wire [`ID_TO_EX_WD-1:0] id_to_ex_bus;
    wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus;
    wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus;
    wire [`BR_WD-1:0] br_bus;
    wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus;
    wire [`StallBus-1:0] stall;
    
    // 数据转发信号
    wire ex_we, mem_we, wb_we;
    wire [4:0] ex_waddr, mem_waddr, wb_waddr;
    wire [31:0] ex_wdata, mem_wdata, wb_wdata;
    
    // HI/LO寄存器值
    wire [31:0] hi_value, lo_value;
    wire hi_we, lo_we;
    wire [31:0] hi_wdata, lo_wdata;
    
    // 暂停请求
    wire stallreq_for_id;
    wire stallreq_for_ex;
    
    // 乘除状态
    wire [1:0] mul_type;
    wire [1:0] div_type;
    wire mul_start, div_start;
    
    // 调试信号
    wire [31:0] id_pc, ex_pc, mem_pc;

    // IF模块 - 指令取指
    IF u_IF(
        .clk             (clk             ),
        .rst             (rst             ),
        .stall           (stall           ),
        .br_bus          (br_bus          ),
        .if_to_id_bus    (if_to_id_bus    ),
        .inst_sram_en    (inst_sram_en    ),
        .inst_sram_wen   (inst_sram_wen   ),
        .inst_sram_addr  (inst_sram_addr  ),
        .inst_sram_wdata (inst_sram_wdata )
    );

    // ID模块 - 指令译码
    ID u_ID(
        .clk             (clk             ),
        .rst             (rst             ),
        .stall           (stall           ),
        .stallreq        (stallreq_for_id ),
        .if_to_id_bus    (if_to_id_bus    ),
        .inst_sram_rdata (inst_sram_rdata ),
        .wb_to_rf_bus    (wb_to_rf_bus    ),
        .id_to_ex_bus    (id_to_ex_bus    ),
        .br_bus          (br_bus          ),
        
        // 数据转发
        .ex_we_i         (ex_we           ),
        .ex_waddr_i      (ex_waddr        ),
        .ex_wdata_i      (ex_wdata        ),
        .mem_we_i        (mem_we          ),
        .mem_waddr_i     (mem_waddr       ),
        .mem_wdata_i     (mem_wdata       ),
        
        // HI/LO寄存器
        .hi_value_i      (hi_value        ),
        .lo_value_i      (lo_value        ),
        
        // 调试信号
        .id_pc_o         (id_pc           )
    );

    // EX模块 - 执行
    EX u_EX(
        .clk             (clk             ),
        .rst             (rst             ),
        .stall           (stall           ),
        .id_to_ex_bus    (id_to_ex_bus    ),
        .ex_to_mem_bus   (ex_to_mem_bus   ),
        
        // 数据转发输出
        .ex_we_o         (ex_we           ),
        .ex_waddr_o      (ex_waddr        ),
        .ex_wdata_o      (ex_wdata        ),
        
        // HI/LO控制
        .hi_we_o         (hi_we           ),
        .hi_wdata_o      (hi_wdata        ),
        .lo_we_o         (lo_we           ),
        .lo_wdata_o      (lo_wdata        ),
        .mul_type_o      (mul_type        ),
        .div_type_o      (div_type        ),
        
        // 访存接口
        .data_sram_en    (data_sram_en    ),
        .data_sram_wen   (data_sram_wen   ),
        .data_sram_addr  (data_sram_addr  ),
        .data_sram_wdata (data_sram_wdata ),
        
        // 暂停请求
        .stallreq        (stallreq_for_ex ),
        
        // 调试信号
        .ex_pc_o         (ex_pc           )
    );

    // MEM模块 - 访存
    MEM u_MEM(
        .clk             (clk             ),
        .rst             (rst             ),
        .stall           (stall           ),
        .ex_to_mem_bus   (ex_to_mem_bus   ),
        .data_sram_rdata (data_sram_rdata ),
        .mem_to_wb_bus   (mem_to_wb_bus   ),
        
        // 数据转发输出
        .mem_we_o        (mem_we          ),
        .mem_waddr_o     (mem_waddr       ),
        .mem_wdata_o     (mem_wdata       ),
        
        // 调试信号
        .mem_pc_o        (mem_pc          )
    );

    // WB模块 - 写回
    WB u_WB(
        .clk               (clk               ),
        .rst               (rst               ),
        .stall             (stall             ),
        .mem_to_wb_bus     (mem_to_wb_bus     ),
        .wb_to_rf_bus      (wb_to_rf_bus      ),
        .debug_wb_pc       (debug_wb_pc       ),
        .debug_wb_rf_wen   (debug_wb_rf_wen   ),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
        .debug_wb_rf_wdata (debug_wb_rf_wdata ),
        
        // 数据转发输出
        .wb_we_o           (wb_we             ),
        .wb_waddr_o        (wb_waddr          ),
        .wb_wdata_o        (wb_wdata          )
    );

    // HI/LO寄存器模块
    hilo_reg u_hilo_reg(
        .clk      (clk      ),
        .rst      (rst      ),
        .hi_we    (hi_we    ),
        .lo_we    (lo_we    ),
        .hi_i     (hi_wdata ),
        .lo_i     (lo_wdata ),
        .hi_o     (hi_value ),
        .lo_o     (lo_value )
    );

    // CTRL模块 - 控制单元
    CTRL u_CTRL(
        .rst                (rst                ),
        .stallreq_for_id    (stallreq_for_id    ),
        .stallreq_for_ex    (stallreq_for_ex    ),
        .mul_type_i         (mul_type           ),
        .div_type_i         (div_type           ),
        .stall              (stall              )
    );

endmodule