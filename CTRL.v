// CTRL.v
`include "lib/defines.vh"
module CTRL(
    input wire rst,
    input wire stallreq_for_id,
    input wire stallreq_for_ex,

    output reg [`StallBus-1:0] stall
);  
    always @ (*) begin
        if (rst) begin
            stall = `StallBus'b0;
        end
        else if (stallreq_for_ex) begin
            // EX段需要暂停（乘除等长周期指令）
            // 暂停IF, ID, EX段
            stall = 6'b001111;
        end
        else if (stallreq_for_id) begin
            // ID段需要暂停（load-use冒险）
            // 暂停IF, ID段
            stall = 6'b000111;
        end
        else begin
            stall = `StallBus'b0;
        end
    end

endmodule