/*******************************************************************************************************************
存放数据的缓冲区
********************************************************************************************************************/
module core_if_addr_data_shift_buff #(
  parameter DEPTH=2
)(
  input  logic        clk,
  input  logic        rest,
  input  logic        write,
  input  logic [31:0] addr,
  input  logic [31:0] data,
  output logic [31:0] all_addr[DEPTH-1:0],
  output logic [31:0] all_data[DEPTH-1:0]
);
/*******************************************************************
存放数据的缓冲区
*******************************************************************/
logic[31:0] data_buff[DEPTH-1:0];
logic[31:0] addr_buff[DEPTH-1:0];

/*******************************************************************
写入控制
*******************************************************************/
always @(posedge clk) begin:block1
  int i;
  if(!rest) begin
    for(i=0;i<DEPTH;i++) begin
      addr_buff[i][31]<=1'd0;
    end
  end
  else begin
    if(write) begin
      addr_buff[0]<=addr;
      data_buff[0]<=data;
      for(i=1;i<DEPTH;i++) begin
        addr_buff[i]<=addr_buff[i-1];
        data_buff[i]<=data_buff[i-1];
      end
    end
  end
end

/*******************************************************************
导出全部数据
*******************************************************************/
always @(*) begin:block2
  int i;
  for(i=0;i<DEPTH;i++) begin
    all_addr[i]=addr_buff[i];
    all_data[i]=data_buff[i];
  end
end

endmodule