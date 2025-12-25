// hilo_reg.v
`include "lib/defines.vh"
module hilo_reg(
    input wire clk,
    input wire rst,
    input wire hi_we,
    input wire lo_we,
    input wire [31:0] hi_i,
    input wire [31:0] lo_i,
    output reg [31:0] hi_o,
    output reg [31:0] lo_o
);

    always @(posedge clk) begin
        if (rst) begin
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
        else begin
            if (hi_we) begin
                hi_o <= hi_i;
            end
            if (lo_we) begin
                lo_o <= lo_i;
            end
        end
    end

endmodule