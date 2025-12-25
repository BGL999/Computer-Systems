// alu.v
`include "lib/defines.vh"
module alu(
    input wire [11:0] alu_control,
    input wire [31:0] alu_src1,
    input wire [31:0] alu_src2,
    output reg [31:0] alu_result
);

    wire op_add  = alu_control[11];
    wire op_sub  = alu_control[10];
    wire op_slt  = alu_control[9];
    wire op_sltu = alu_control[8];
    wire op_and  = alu_control[7];
    wire op_nor  = alu_control[6];
    wire op_or   = alu_control[5];
    wire op_xor  = alu_control[4];
    wire op_sll  = alu_control[3];
    wire op_srl  = alu_control[2];
    wire op_sra  = alu_control[1];
    wire op_lui  = alu_control[0];

    wire [31:0] add_sub_result;
    wire [31:0] slt_result;
    wire [31:0] sltu_result;
    wire [31:0] and_result;
    wire [31:0] nor_result;
    wire [31:0] or_result;
    wire [31:0] xor_result;
    wire [31:0] sll_result;
    wire [31:0] srl_result;
    wire [31:0] sra_result;
    wire [31:0] lui_result;

    // 加减法
    assign add_sub_result = op_sub ? (alu_src1 - alu_src2) : (alu_src1 + alu_src2);

    // 比较
    assign slt_result = ($signed(alu_src1) < $signed(alu_src2)) ? 32'b1 : 32'b0;
    assign sltu_result = (alu_src1 < alu_src2) ? 32'b1 : 32'b0;

    // 逻辑运算
    assign and_result = alu_src1 & alu_src2;
    assign nor_result = ~(alu_src1 | alu_src2);
    assign or_result = alu_src1 | alu_src2;
    assign xor_result = alu_src1 ^ alu_src2;

    // 移位
    assign sll_result = alu_src2 << alu_src1[4:0];
    assign srl_result = alu_src2 >> alu_src1[4:0];
    assign sra_result = $signed(alu_src2) >>> alu_src1[4:0];

    // LUI
    assign lui_result = {alu_src2[15:0], 16'b0};

    // 结果选择
    always @(*) begin
        case (1'b1)
            op_add:  alu_result = add_sub_result;
            op_sub:  alu_result = add_sub_result;
            op_slt:  alu_result = slt_result;
            op_sltu: alu_result = sltu_result;
            op_and:  alu_result = and_result;
            op_nor:  alu_result = nor_result;
            op_or:   alu_result = or_result;
            op_xor:  alu_result = xor_result;
            op_sll:  alu_result = sll_result;
            op_srl:  alu_result = srl_result;
            op_sra:  alu_result = sra_result;
            op_lui:  alu_result = lui_result;
            default: alu_result = `ZeroWord;
        endcase
    end

endmodule