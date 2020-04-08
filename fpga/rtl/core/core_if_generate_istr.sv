/*******************************************************************************************************************
获取指令
********************************************************************************************************************/
module core_if_generate_istr #(
  parameter SHIFT_BUFF_MAX_NUM=2,
            WAIT_FIFO_MAX_NUM=2
)(
  input  logic[31:0] all_valid_addr[SHIFT_BUFF_MAX_NUM:0],
  input  logic[31:0] all_sent_addr[WAIT_FIFO_MAX_NUM-1:0],
  input  logic[31:0] all_valid_data[SHIFT_BUFF_MAX_NUM:0],
  input  logic[31:0] pc,
  output logic[1:0 ] pc_read_data_request,
  output logic[31:0] istr,
  output logic       istr_valid
);
/*******************************************************************
参数
*******************************************************************/
localparam ISTR_SEL_WIDTH=$clog2((SHIFT_BUFF_MAX_NUM+1)*2);

/*******************************************************************
变量
*******************************************************************/
logic[31:0]                  pf_addr[1:0];
logic[SHIFT_BUFF_MAX_NUM:0]  addr_is_exist[1:0];
logic                        addr_is_sent[1:0];
logic[1:0][15:0]             istrs;
logic[ISTR_SEL_WIDTH-1:0]    istrs_0_sel;
logic[ISTR_SEL_WIDTH-1:0]    istrs_1_sel;

/*******************************************************************
连线
*******************************************************************/
assign istr=istrs;

/*******************************************************************
获取当前指令所处的地址和下一个地址
*******************************************************************/
always @(*) begin:block1
  int i;
  for(i=0;i<2;i++) begin
    pf_addr[i]={pc[31:2],2'd0}+i*4;
  end
end

/*******************************************************************
检查需要的地址是否存在或者已经发送到总线
*******************************************************************/
always @(*) begin:block2
  int i,j;
  for(i=0;i<2;i++) begin
    for(j=0;j<SHIFT_BUFF_MAX_NUM+1;j++) begin
      addr_is_exist[i][j]=((pf_addr[i][31:2]==all_valid_addr[j][29:0])&&all_valid_addr[j][31]);
    end
    addr_is_sent[i]=1'd0;
    for(j=0;j<WAIT_FIFO_MAX_NUM;j++) begin
      addr_is_sent[i]=addr_is_sent[i]||((pf_addr[i][31:2]==all_sent_addr[j][29:0])&&all_sent_addr[j][31]);
    end
  end
end

/*******************************************************************
求出sel
*******************************************************************/
always @(*) begin:block3
  int i;
  for(i=0;i<SHIFT_BUFF_MAX_NUM+1;i++) begin
    if(addr_is_exist[0][i]) begin
      break;
    end
  end
  istrs_0_sel=(i[ISTR_SEL_WIDTH-2:0]<<1)|pc[1];
  for(i=0;i<SHIFT_BUFF_MAX_NUM+1;i++) begin
    if(addr_is_exist[1][i]) begin
      break;
    end
  end
  istrs_1_sel=pc[1]?(i[ISTR_SEL_WIDTH-2:0]<<1)|!pc[1]:istrs_0_sel+1'b1;
end

/*******************************************************************
取出指令
*******************************************************************/
assign istrs[0]=istrs_0_sel[0]?all_valid_data[istrs_0_sel/2][31:16]:all_valid_data[istrs_0_sel/2][15:0];
assign istrs[1]=istrs_1_sel[0]?all_valid_data[istrs_1_sel/2][31:16]:all_valid_data[istrs_1_sel/2][15:0];
assign istr_valid=((istrs[0][1:0]!=2'h3)||(addr_is_exist[1]!=0))&&(addr_is_exist[0]!=0);

/*******************************************************************
发出读请求
*******************************************************************/
assign pc_read_data_request[0]=(addr_is_exist[0]==0)&&(addr_is_sent[0]==0);
assign pc_read_data_request[1]=(addr_is_exist[1]==0)&&(addr_is_sent[1]==0)&&(addr_is_exist[0]!=0)&&(istrs[0][1:0]==2'h3)&&pc[1];

endmodule