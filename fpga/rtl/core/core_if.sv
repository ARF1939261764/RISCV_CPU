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
  output  logic[31:0]   fd_istr,
  output  logic[31:0]   fd_pc,
  output  logic         fd_valid,
  output  logic         fd_jump,
  input   logic         fd_ready,
  /*其它控制信号*/
  input   logic         ctr_stop            /*停止cpu*/
);
localparam  PREFETCHED_NUM = 2,             /*预取多少个内存单元(至少两个)*/
            WAIT_FIFO_MAX_NUM=2,            /*等待队列深度*/
            SHIFT_BUFF_MAX_NUM=2,           /*移位缓冲区大小*/
            ISTR_FIFO_WIDTH=$bits(
              {
                fd_istr,
                fd_pc,
                fd_jump
              }
            );
`define     ISTR_MRET       (32'h30200073)  /*mret指令*/
genvar      i;
reg [31:0]  pc;
wire        pc_en;
reg         pc_valid;
logic[31:0] next_pc;
logic[2:0]  next_pc_sel;
wire[2:0]   pc_offset;
wire        istr_valid;                     /*指令有效,表示已经取到了当前pc对应的指令*/
wire        istr_is_mret;
logic       if_stop;

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
/*指令fifo*/
logic                       istr_fifo_flush;
logic                       istr_fifo_full;
logic                       istr_fifo_empty;
logic                       istr_fifo_half;
logic                       istr_fifo_write;
logic                       istr_fifo_read;
logic [ISTR_FIFO_WIDTH-1:0] istr_fifo_write_data;
logic [ISTR_FIFO_WIDTH-1:0] istr_fifo_read_data;
/**********************************************************************************
连线
**********************************************************************************/
assign pc_en                              = ((!pc_valid||istr_valid||jump_en)&&!if_stop)||flush_en; /*计算下一个pc,如果EX级发过来的jump_en信号有效则立即跳转*/
/*移位缓冲区*/
assign shift_fifo_write                   = avl_m0.read_data_valid&&!wait_fifo_empty;
assign shift_fifo_addr                    = wait_fifo_read_data;
assign shift_fifo_data                    = avl_m0.read_data;
/*等待队列*/
assign wait_fifo_write                    = avl_m0.read&&avl_m0.request_ready;
assign wait_fifo_write_data               = {1'd1,1'd0,avl_m0.address[31:2]};
assign wait_fifo_read                     = avl_m0.read_data_valid;
/*地址生成*/
assign generate_addr_next_pc              = next_pc;
assign generate_addr_pc                   = pc;
assign generate_addr_pc_read_data_request = generate_istr_pc_read_data_request;
generate
  for(i=0;i<WAIT_FIFO_MAX_NUM;i++) begin:block1
    assign generate_addr_all_sent_addr[i]=wait_fifo_all_data[i];
  end
  for(i=WAIT_FIFO_MAX_NUM;i<WAIT_FIFO_MAX_NUM+SHIFT_BUFF_MAX_NUM;i++) begin:block2
    assign generate_addr_all_sent_addr[i]=shift_fifo_all_addr[i-WAIT_FIFO_MAX_NUM];
  end
endgenerate
/*指令生成*/
generate
  for(i=0;i<SHIFT_BUFF_MAX_NUM;i++) begin:block3
    assign generate_istr_all_valid_addr[i]=shift_fifo_all_addr[i];
    assign generate_istr_all_valid_data[i]=shift_fifo_all_data[i];
  end
  assign generate_istr_all_valid_addr[SHIFT_BUFF_MAX_NUM]={avl_m0.read_data_valid,1'd0,wait_fifo_read_data[29:0]};
  assign generate_istr_all_valid_data[SHIFT_BUFF_MAX_NUM]=avl_m0.read_data;
  for(i=0;i<WAIT_FIFO_MAX_NUM;i++) begin:block4
    assign generate_istr_all_sent_addr[i]=wait_fifo_all_data[i];
  end
endgenerate
assign generate_istr_pc=pc;

/*指令fifo*/
assign istr_fifo_flush          = flush_en;
assign istr_fifo_write          = istr_valid&&!flush_en;
assign istr_fifo_write_data     = {generate_istr_istr,pc,bp_jump_en||istr_is_mret};
assign istr_fifo_read           = fd_ready;

/*从fifo中读出指令给到下一级*/  
assign {fd_istr,fd_pc,fd_jump}  = istr_fifo_read_data;
assign fd_valid                 = !istr_fifo_empty;

/*其它*/
assign istr_valid                         = generate_istr_istr_valid&&!if_stop;
assign avl_m0.read                        = generate_addr_read;
assign avl_m0.address                     = generate_addr_read_addr;
assign pc_offset                          = (generate_istr_istr[1:0]==2'd3)?3'd4:3'd2;
assign istr_is_mret                       = istr_valid&&(generate_istr_istr==`ISTR_MRET);
assign avl_m0.write                       = 1'd0;
assign avl_m0.write_data                  = 32'd0;
assign avl_m0.byte_en                     = 4'hf;
assign avl_m0.begin_burst_transfer        = 1'd0;
assign avl_m0.burst_count                 = 0;
assign bp_istr                            = generate_istr_istr;
assign bp_pc                              = pc;
assign if_stop                            = ctr_stop||istr_fifo_full;

/*计算next_pc_sel*/
always @(*) begin
  if(jump_en) begin
    next_pc_sel<=4'd2;
  end
  else if(bp_jump_en||istr_is_mret) begin
    next_pc_sel<=bp_jump_en?4'd3:4'd1;
  end
  else if(istr_valid) begin
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
  .flush                (1'd0                               ),
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
指令生成
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
/**********************************************************************************
指令fifo
**********************************************************************************/
fifo_sync #(
  .DEPTH(2               ),
  .WIDTH(ISTR_FIFO_WIDTH )
)
fifo_sync_inst0_istr_fifo(
  .clk        (clk                  ),
  .rest       (rest                 ),
  .flush      (istr_fifo_flush      ),
  .full       (istr_fifo_full       ),
  .empty      (istr_fifo_empty      ),
  .half       (istr_fifo_half       ),
  .write      (istr_fifo_write      ),
  .read       (istr_fifo_read       ),
  .write_data (istr_fifo_write_data ),
  .read_data  (istr_fifo_read_data  )
);

endmodule
