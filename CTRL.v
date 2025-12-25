// CTRL.v
`include "lib/defines.vh"
module CTRL(
    input wire rst,
    input wire stallreq_for_id,
    input wire stallreq_for_ex,
    input wire [1:0] mul_type_i,
    input wire [1:0] div_type_i,

    output reg [`StallBus-1:0] stall
);  
    // 乘除暂停周期数（简化处理，实际需要根据乘除器状态）
    reg [4:0] mul_counter;
    reg [4:0] div_counter;
    
    always @(*) begin
        if (rst) begin
            stall = `StallBus'b0;
            mul_counter = 5'b0;
            div_counter = 5'b0;
        end
        else begin
            // 默认无暂停
            stall = `StallBus'b0;
            
            // 乘除指令暂停处理（简化：固定周期数）
            if (mul_type_i != `MUL_TYPE_NONE) begin
                // 假设乘法需要5个周期
                stall = 6'b001111; // 暂停IF, ID, EX
                // 这里应该有计数器逻辑，实际中需要根据乘除器的ready信号
            end
            else if (div_type_i != `DIV_TYPE_NONE) begin
                // 假设除法需要10个周期
                stall = 6'b001111; // 暂停IF, ID, EX
                // 这里应该有计数器逻辑
            end
            // load-use冒险暂停
            else if (stallreq_for_id) begin
                stall = 6'b000111; // 暂停IF, ID
            end
            // 其他EX段暂停请求
            else if (stallreq_for_ex) begin
                stall = 6'b001111; // 暂停IF, ID, EX
            end
        end
    end

endmodule