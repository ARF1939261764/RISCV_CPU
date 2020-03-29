/**********************************************************************************
寄存器文件模块
**********************************************************************************/
module core_id_reg_file(
  input  logic        clk,
  input  logic[4:0]   read_0_addr,
  output logic[31:0]  read_0_data,
  input  logic[4:0]   read_1_addr,
  output logic[31:0]  read_1_data,
  input  logic[4:0]   write_addr,
  input  logic[31:0]  write_data,
  input  logic        write_en
);
/*寄存器组*/
logic[31:0] regs[31:0];
/*读控制*/
always @(*) begin
  read_0_data=regs[read_0_addr];
  read_1_data=regs[read_1_addr];
end
/*写控制*/
always @(posedge clk) begin
  if(write_en) begin
    regs[write_addr]<=write_data;
  end
end
endmodule
