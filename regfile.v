// regfile.v
`include "lib/defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output reg [31:0] rdata1,
    input wire [4:0] raddr2,
    output reg [31:0] rdata2,
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata
);

    reg [31:0] regs[0:31];

    // 初始化寄存器
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            regs[i] = 32'b0;
        end
    end

    // 读端口1
    always @(*) begin
        if (raddr1 == 5'b0) begin
            rdata1 = `ZeroWord;
        end
        else if (we && (waddr == raddr1)) begin
            rdata1 = wdata; // 转发
        end
        else begin
            rdata1 = regs[raddr1];
        end
    end

    // 读端口2
    always @(*) begin
        if (raddr2 == 5'b0) begin
            rdata2 = `ZeroWord;
        end
        else if (we && (waddr == raddr2)) begin
            rdata2 = wdata; // 转发
        end
        else begin
            rdata2 = regs[raddr2];
        end
    end

    // 写端口
    always @(posedge clk) begin
        if (we && (waddr != 5'b0)) begin
            regs[waddr] <= wdata;
        end
    end

endmodule