`include "core_define.sv"
module core_ex_alu(
  input  logic       clk,
  input  logic       rest,
  input  logic[4:0]  op,
  input  logic       op_wait_handle,
  output logic       op_ready,
  input  logic[31:0] in1,
  input  logic[31:0] in2,
  output logic[31:0] out
);
/**************************************************************
变量
**************************************************************/
logic       shift_lr;
logic       shift_la;
logic[31:0] shift_in1;
logic[4:0]  shift_shfit_bit;
logic[31:0] shift_out;

/**************************************************************
判断移位方向
返回值:
  0:左移
  1:右移
**************************************************************/
function logic judge_shift_lr(input[4:0] op);
  return op[4];
endfunction

/**************************************************************
判断是逻辑移位还是算术移位
返回值:
  0:逻辑
  1:算术
**************************************************************/
function logic judge_shift_la(input[4:0] op);
  return op[1];
endfunction

/**************************************************************
连线
**************************************************************/
assign shift_lr         = op!=`ALU_OP_SLL;
assign shift_la         = op==`ALU_OP_SRA;
assign shift_in1        = in1;
assign shift_shfit_bit  = in2[4:0];
assign op_ready=1'd1;

/*译码,选择对应的输出*/
always @(*) begin
  case(op)
    `ALU_OP_ADD    :out=in1+in2;
    `ALU_OP_SUB    :out=in1-in2;
    `ALU_OP_SLL    :out=shift_out;
    `ALU_OP_SLT    :out=(signed'(in1)<signed'(in2))?1'd1:1'd0;
    `ALU_OP_SLTU   :out=(unsigned'(in1)<unsigned'(in2))?1'd1:1'd0;
    `ALU_OP_XOR    :out=in1^in2;
    `ALU_OP_SRL    :out=shift_out;
    `ALU_OP_SRA    :out=shift_out;
    `ALU_OP_OR     :out=in1|in2;
    `ALU_OP_AND    :out=in1&in2;
    `ALU_OP_NOT_AND:out=~in1&in2;
    default:out=in1;
  endcase
end

/**************************************************************
模块实例化
**************************************************************/
core_ex_alu_shift core_ex_alu_shift_inst0(
  .lr       (shift_lr       ),
  .la       (shift_la       ),
  .in1      (shift_in1      ),
  .shfit_bit(shift_shfit_bit),
  .out      (shift_out      )
);

endmodule
