module uart (
  input logic     clk,
  input logic     rest,
  i_avl_bus.slave avl_s0,
  input           rx,
  output          tx
);
/***************************************************************************
寄存器组
***************************************************************************/
logic[15:0] reg_div;
logic[31:0] reg_sr;
logic[7:0]  reg_t_dr;
logic[7:0]  reg_r_dr;
logic[7:0]  reg_rcv_count;
/***************************************************************************
变量
***************************************************************************/
logic       send_start;
logic[10:0] t_data;
logic[15:0] t_baud_count;
logic[3:0]  t_count;
logic       send_done;
/***************************************************************************
读写寄存器控制
***************************************************************************/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    reg_div <= 0;
  end
  else begin
    if(avl_s0.write) begin
      if(avl_s0.address[3:2]==2'd0) reg_div<=avl_s0.write_data[15:0];
      if(avl_s0.address[3:2]==2'd2) reg_t_dr<=avl_s0.write_data[7:0];
    end
    else begin
      if(avl_s0.read) begin
        case(avl_s0.address[3:2])
          2'd0:avl_s0.read_data<={15'd0,reg_div};
          2'd1:avl_s0.read_data<=reg_sr;
          2'd2:avl_s0.read_data<={24'd0,reg_r_dr};
          2'd3:avl_s0.read_data<={24'd0,reg_rcv_count};
          default:begin end
        endcase
      end
    end
  end
end
always @(posedge clk) begin
  avl_s0.read_data_valid<=avl_s0.read;
end
assign avl_s0.request_ready = 1;
/***************************************************************************
发送数据
***************************************************************************/
assign t_data={2'd3,reg_t_dr,1'd0};
assign send_start = avl_s0.write&&avl_s0.address[3:2]==2'd2;
/*产生指定波特率信号*/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    t_baud_count<=1'd0;
  end
  else begin
    if(send_start||(t_baud_count==reg_div)) begin
      t_baud_count<=0;
    end
    else begin
      t_baud_count<=t_baud_count+1;
    end
    
  end
end
/*发送*/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    t_count<=4'd10;
  end
  else begin
    if(send_start) begin
      t_count<=0;
    end
    else begin
      if((t_baud_count==reg_div) && (t_count != 4'd10)) begin
        t_count=t_count+1;
      end
    end
  end
end
assign tx = t_data[t_count];
/*状态机存器管理*/
assign send_done = t_count == 4'd10;
assign reg_sr[0] = send_done;
/***************************************************************************
接收数据
***************************************************************************/


endmodule
