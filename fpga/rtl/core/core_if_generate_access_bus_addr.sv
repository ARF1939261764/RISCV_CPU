/*******************************************************************************************************************
地址生成模块
********************************************************************************************************************/
module core_if_generate_access_bus_addr #(
  parameter WAIT_FIFO_MAX_NUM=2,
            SHIFT_BUFF_MAX_NUM=2,
            PREFETCHED_NUM=2
)(
  input  logic[31:0] next_pc,
  input  logic[31:0] pc,
  input  logic[1:0]  pc_read_data_request,
  input  logic[31:0] all_sent_addr[WAIT_FIFO_MAX_NUM+SHIFT_BUFF_MAX_NUM-1:0],
  output logic[31:0] read_addr,
  output logic       read
);
/*******************************************************************
变量定义
*******************************************************************/
logic[31:0]               pf_addr[PREFETCHED_NUM-1:0];
logic[PREFETCHED_NUM-1:0] addr_is_sent;
logic[2:0]                read_addr_sel;
/*******************************************************************
获取next_pc,next_pc+4,...,next_pc+(PREFETCHED_NUM-1)*4
*******************************************************************/
always @(*) begin:block1
  int i;
  for(i=0;i<PREFETCHED_NUM;i++) begin
    pf_addr[i]={next_pc[31:2],2'd0}+i*4;
  end
end
/*******************************************************************
检查需要预取的数据是否都已经取出，或者已经发送了对应的命令到总线
*******************************************************************/
always @(*) begin:block2
  int i,j;
  for(i=0;i<PREFETCHED_NUM;i++) begin
    addr_is_sent[i]=0;
    for(j=0;j<WAIT_FIFO_MAX_NUM+SHIFT_BUFF_MAX_NUM;j++) begin
      addr_is_sent[i]=addr_is_sent[i]||((pf_addr[i][31:2]==all_sent_addr[j][29:0])&&all_sent_addr[j][31]);
    end
  end
end
/*******************************************************************
根据pc_read_data_request和addr_is_sent得到read_addr_sel
*******************************************************************/
always @(*) begin:block3
  int i;
  if(pc_read_data_request!=2'd0) begin
    read_addr_sel=(pc_read_data_request[0]?3'd0:3'd1)+PREFETCHED_NUM[2:0];
    read=1'd1;
  end
  else if(addr_is_sent!={PREFETCHED_NUM{1'd1}})begin
    for(i=0;i<PREFETCHED_NUM;i++) begin
      if(!addr_is_sent[i]) begin
        break;
      end
    end
    read_addr_sel=i[2:0];
    read=1'd1;
  end
  else begin
    read_addr_sel=3'd0;
    read=1'd0;
  end
end
/*******************************************************************
根据read_addr_sel选择对应的数据
*******************************************************************/
always @(*) begin
  case(read_addr_sel)
    3'd0+PREFETCHED_NUM:read_addr=pc;
    3'd1+PREFETCHED_NUM:read_addr=pc+4;
    default:read_addr=pf_addr[read_addr_sel];
  endcase
end

endmodule