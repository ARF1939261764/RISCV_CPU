module core_ifu(
  input                 clk,
  input                 rest,
  /*主机接口,访问总线*/
  i_avl_bus.master      avl_m0,
  /*跳转，冲刷控制*/
  input   logic[31:0]   jump_addr,
  input   logic         jump_en,
  input   logic         flush_en,
  /*分支预测接口*/
  output  logic[31:0]   bp_istr,
  output  logic[31:0]   bp_pc,
  input   logic         bp_jump_em,
  /*指令交付给下一级*/
  output  logic[31:0]   dely_istr,
  output  logic[31:0]   dely_pc,
  output  logic         dely_valid,
  input   logic         dely_ready
);



endmodule
