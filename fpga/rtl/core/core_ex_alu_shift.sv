module core_ex_alu_shift(
  input   logic       lr,
  input   logic       la,
  input   logic[31:0] in1,
  input   logic[4:0]  shfit_bit,
  output  logic[31:0] out
);

logic[31:0] logic_shift;
logic[31:0] arith_shift;
assign logic_shift=lr?in1>>shfit_bit:in1<<shfit_bit;
assign arith_shift=logic_shift|({32{in1[31]}}<<(32-shfit_bit));
assign out=la?arith_shift:logic_shift;

endmodule