module core_if #(
  parameter REST_ADDR = 32'd0
)(
  input                 clk,
  input                 rest,
  /*主机接口,访问总线*/
  i_avl_bus.master      avl_m0,
  /*跳转，冲刷控制*/
  input   logic[31:0]   csr_mepc,
  input   logic[31:0]   jump_addr,
  input   logic         jump_en,
  input   logic         flush_en,
  /*分支预测接口*/
  output  logic[31:0]   bp_istr,
  output  logic[31:0]   bp_pc,
  input   logic[31:0]   bp_jump_addr,
  input   logic         bp_jump_en,
  /*指令交付给下一级*/
  output  logic[31:0]   dely_istr,
  output  logic[31:0]   dely_pc,
  output  logic         dely_valid,
  input   logic         dely_ready
);
reg [31:0] pc;
wire       pc_en;
reg        pc_valid;
wire[31:0] next_pc;
wire[2:0]  next_pc_sel;
wire[2:0]  pc_offset;

wire       istr_valid;

/*计算下一个pc*/
assign pc_en=!pc_valid||istr_valid;

/*计算下一个pc*/
always @(*) begin
  case(next_pc_sel)
    4'd0:next_pc=pc;            /*不动*/
    4'd1:next_pc=csr_mepc;      /*异常返回*/
    4'd2:next_pc=jump_addr;     /*跳转到指定的地址,该地址由EX模块提供*/
    4'd3:next_pc=bp_jump_addr;  /*分支跳转,跳转地址由分支预测器提供*/
    4'd4:next_pc=pc+pc_offset;  /*pc自加*/
    default:next_pc=REST_ADDR;  /*发生异常,返回到复位地址*/
  endcase
end
/*表示当前pc寄存器中的值是否有效(除了复位后的第一个时钟周期外,其余时间全部有效)*/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    pc_valid<=1'd0;
  end
  else begin
    pc_valid<=1'd1;
  end
end
/*获取下一个代取指令的pc值*/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    pc<=REST_ADDR;
  end
  else begin
    if(pc_en) begin
      pc<=next_pc;
    end
  end
end


endmodule
