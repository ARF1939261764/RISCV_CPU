module core_ex_alu(
  input  logic       clk,
  input  logic       rest,
  input  logic[4:0]  op,
  input  logic       op_valid,
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
assign shift_lr         = judge_shift_lr(op);
assign shift_la         = judge_shift_la(op);
assign shift_in1        = in1;
assign shift_shfit_bit  = in2[4:0];
assign op_ready=1'd1;

/*译码,选择对应的输出*/
always @(*) begin
  case(op)
    5'b0000:out=in1+in2;
    5'b0001:out=in1-in2;
    5'b0010:out=shift_out;
    5'b1010:out=shift_out;
    5'b1011:out=shift_out;
    5'b0100:out=(signed'(in1)<signed'(in2))?1'd1:1'd0;
    5'b0110:out=(unsigned'(in1)<unsigned'(in2))?1'd1:1'd0;
    5'b1000:out=in1^in2;
    5'b1100:out=in1|in2;
    5'b1110:out=in1&in2;
    5'b1111:out=in1;
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
