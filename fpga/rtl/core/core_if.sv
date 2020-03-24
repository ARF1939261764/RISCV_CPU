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
localparam  PREFETCHED_NUM = 2,/*预取多少个内存单元(至少两个)*/
            WAIT_FIFO_MAX_NUM=2,
            SHIFT_BUFF_MAX_NUM=2;
`define     ISTR_MRET       (32'b00110000001000000000000000000011)
genvar      i;
reg [31:0]  pc;
wire        pc_en;
reg         pc_valid;
wire[31:0]  next_pc;
wire[2:0]   next_pc_sel;
wire[2:0]   pc_offset;
wire        istr_valid;      /*指令有效,表示已经取到了当前pc对应的指令*/
wire        istr_is_mret;

/**shift fifo的端口****/
logic       shift_fifo_write;
logic[31:0] shift_fifo_addr;
logic[31:0] shift_fifo_data;
logic[31:0] shift_fifo_all_addr[SHIFT_BUFF_MAX_NUM-1:0];
logic[31:0] shift_fifo_all_data[SHIFT_BUFF_MAX_NUM-1:0];
/**wait fifo的端口**/
logic       wait_fifo_full;
logic       wait_fifo_empty;
logic       wait_fifo_half;
logic       wait_fifo_write;
logic[31:0] wait_fifo_write_data;
logic       wait_fifo_read;
logic[31:0] wait_fifo_read_data;
logic[31:0] wait_fifo_all_data[WAIT_FIFO_MAX_NUM-1:0];
/**generate addr模块**/
logic[31:0] generate_addr_next_pc;
logic[31:0] generate_addr_pc;
logic[1:0]  generate_addr_pc_read_data_request;
logic[31:0] generate_addr_all_sent_addr[WAIT_FIFO_MAX_NUM+SHIFT_BUFF_MAX_NUM-1:0];
logic[31:0] generate_addr_read_addr;
logic       generate_addr_read;
/**generate istr模块**/
logic[31:0] generate_istr_all_valid_addr[SHIFT_BUFF_MAX_NUM:0];
logic[31:0] generate_istr_all_sent_addr[WAIT_FIFO_MAX_NUM-1:0];
logic[31:0] generate_istr_all_valid_data[SHIFT_BUFF_MAX_NUM:0];
logic[31:0] generate_istr_pc;
logic[1:0]  generate_istr_pc_read_data_request;
logic[31:0] generate_istr_istr;
logic       generate_istr_istr_valid;
/**********************************************************************************
连线
**********************************************************************************/
assign pc_en                              = !pc_valid||istr_valid; /*计算下一个pc*/

assign shift_fifo_write                   = avl_m0.read_data_valid;
assign shift_fifo_addr                    = wait_fifo_read_data;
assign shift_fifo_data                    = avl_m0.read_data;

assign wait_fifo_write                    = avl_m0.read&&avl_m0.request_ready;
assign wait_fifo_write_data               = {1'd1,1'd0,avl_m0.address[29:0]};
assign wait_fifo_read                     = avl_m0.read_data_valid;

assign generate_addr_next_pc              = next_pc;
assign generate_addr_pc                   = pc;
assign generate_addr_pc_read_data_request = generate_istr_pc_read_data_request;
generate
  for(i=0;i<WAIT_FIFO_MAX_NUM;i++) begin:block1
    assign generate_addr_all_sent_addr[i]=wait_fifo_all_data[i];
  end
  for(i=i;i<WAIT_FIFO_MAX_NUM+SHIFT_BUFF_MAX_NUM;i++) begin:block2
    assign generate_addr_all_sent_addr[i]=shift_fifo_all_addr[i-WAIT_FIFO_MAX_NUM];
  end
endgenerate

generate
  for(i=0;i<SHIFT_BUFF_MAX_NUM;i++) begin:block3
    assign generate_istr_all_valid_addr[i]=shift_fifo_all_addr[i];
    assign generate_istr_all_valid_data[i]=shift_fifo_all_data[i];
  end
  assign generate_istr_all_valid_addr[i]=wait_fifo_read_data;
  assign generate_istr_all_valid_data[i]=avl_m0.read_data;
  for(i=0;i<WAIT_FIFO_MAX_NUM;i++) begin:block4
    assign generate_istr_all_sent_addr[i]=wait_fifo_all_data[i];
  end
endgenerate
assign generate_istr_pc=pc;

assign istr_valid                         = generate_istr_istr_valid;
assign avl_m0.read                        = generate_addr_read;
assign avl_m0.address                     = generate_addr_read_addr;
assign pc_offset                          = (generate_istr_istr[1:0]==2'd3)?(3'd4):3'd2;
assign istr_is_mret                       = generate_istr_istr_valid&&(generate_istr_istr==`ISTR_MRET);
assign avl_m0.write                       = 1'd0;
assign avl_m0.write_data                  = 32'd0;
assign avl_m0.byte_en                     = 4'hf;
assign avl_m0.begin_burst_transfer        = 1'd0;
assign avl_m0.burst_count                 = 0;
assign bp_istr                            = generate_istr_istr;
assign bp_pc                              = pc;

/*寄存器打一拍再送出去，不然组合逻辑太多了*/
always @(posedge clk) begin
  dely_istr<=generate_istr_istr;
  dely_valid<=generate_istr_istr_valid&!flush_en;
  dely_pc<=pc;
end

always @(*) begin
  if(jump_en) begin
    next_pc_sel<=4'd2;
  end
  else if(bp_jump_en||istr_is_mret) begin
    next_pc_sel<=bp_jump_en?4'd3:4'd1;
  end
  else if(generate_istr_istr_valid) begin
    next_pc_sel<=4'd4;
  end
  else begin
    next_pc_sel=4'd0;
  end
end
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

/**********************************************************************************
module实例化，移位缓冲模块:保存最近读到的一些数据
**********************************************************************************/
core_if_addr_data_shift_buff #(
  .DEPTH(SHIFT_BUFF_MAX_NUM)
)
core_if_addr_data_shift_buff_inst0(
  .clk                  (clk                                ),
  .rest                 (rest                               ),
  .write                (shift_fifo_write                   ),
  .addr                 (shift_fifo_addr                    ),
  .data                 (shift_fifo_data                    ),
  .all_addr             (shift_fifo_all_addr                ),
  .all_data             (shift_fifo_all_data                )
);
/**********************************************************************************
同步FIFO:存放已经发送到总线，但是还未返回数据的读命令的地址
**********************************************************************************/
fifo_sync #(
  .DEPTH(WAIT_FIFO_MAX_NUM),
  .WIDTH(32)
)
fifo_sync_inst0_wait_data_valid(
  .clk                  (clk                                ),
  .rest                 (rest                               ),
  .full                 (wait_fifo_full                     ),
  .empty                (wait_fifo_empty                    ),
  .half                 (wait_fifo_half                     ),
  .write                (wait_fifo_write                    ),
  .read                 (wait_fifo_read                     ),
  .write_data           (wait_fifo_write_data               ),
  .read_data            (wait_fifo_read_data                ),
  .all_data             (wait_fifo_all_data                 )
);
/**********************************************************************************
读总线地址生成
**********************************************************************************/
core_if_generate_access_bus_addr #(
  .WAIT_FIFO_MAX_NUM(WAIT_FIFO_MAX_NUM),
  .SHIFT_BUFF_MAX_NUM(SHIFT_BUFF_MAX_NUM),
  .PREFETCHED_NUM(PREFETCHED_NUM)
)
core_if_generate_access_bus_addr_inst0(
  .next_pc              (generate_addr_next_pc              ),
  .pc                   (generate_addr_pc                   ),
  .pc_read_data_request (generate_addr_pc_read_data_request ),
  .all_sent_addr        (generate_addr_all_sent_addr        ),
  .read_addr            (generate_addr_read_addr            ),
  .read                 (generate_addr_read                 )
);
/**********************************************************************************
读取指令
**********************************************************************************/
core_if_generate_istr #(
  .SHIFT_BUFF_MAX_NUM(SHIFT_BUFF_MAX_NUM),
  .WAIT_FIFO_MAX_NUM(WAIT_FIFO_MAX_NUM)
)
core_if_generate_istr_inst0(
  .all_valid_addr       (generate_istr_all_valid_addr       ),
  .all_sent_addr        (generate_istr_all_sent_addr        ),
  .all_valid_data       (generate_istr_all_valid_data       ),
  .pc                   (generate_istr_pc                   ),
  .pc_read_data_request (generate_istr_pc_read_data_request ),
  .istr                 (generate_istr_istr                 ),
  .istr_valid           (generate_istr_istr_valid           )
);

endmodule

/*------------------------------------------------分割线-----------------------------------------------------------------------------------------------*/
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

/*------------------------------------------------分割线-----------------------------------------------------------------------------------------------*/
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

/*------------------------------------------------分割线-----------------------------------------------------------------------------------------------*/
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
  istrs_1_sel=(i[ISTR_SEL_WIDTH-2:0]<<1)|!pc[1];
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
