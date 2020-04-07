/**********************************************************************************
寄存器文件模块
**********************************************************************************/
module core_id_reg_file(
  input  logic        clk,
  input  logic[4:0]   read_0_addr,
  output logic[31:0]  read_0_data,
  input  logic        read_0_en,
  input  logic[4:0]   read_1_addr,
  output logic[31:0]  read_1_data,
  input  logic        read_1_en,
  input  logic[4:0]   write_addr,
  input  logic[31:0]  write_data,
  input  logic        write_en
);

/*寄存器组*/
logic[31:0] regs[31:0];
logic[31:0] temp_data_0,temp_data_1;
logic[4:0]  temp_addr_0,temp_addr_1;
/*读写控制*/
always @(posedge clk) begin
  /*读取数据*/
  if(read_0_en) begin
    temp_addr_0=read_0_addr;
  end
  if(read_1_en) begin
    temp_addr_1=read_1_addr;
  end
  /*写*/
  if(write_en) begin
    regs[write_addr]=write_data;
  end
end
/*选择*/
assign temp_data_0=regs[temp_addr_0];
assign temp_data_1=regs[temp_addr_1];
assign read_0_data=(temp_addr_0==1'd0)?32'd0:temp_data_0;
assign read_1_data=(temp_addr_1==1'd0)?32'd0:temp_data_1;

endmodule
