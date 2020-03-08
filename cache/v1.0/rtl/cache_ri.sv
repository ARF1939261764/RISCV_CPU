`include "cache_define.sv"

module cache_ri #(
  parameter DATA_RAM_ADDR_WIDTH=9,
            TAG_RAM_ADDR_WIDTH=5,
            DRE_RAM_ADDR_WIDTH=8,
            TAG_ADDR_WIDTH =21  
)(
  input  logic                                         clk,
  input  logic                                         rest,

  output logic  [31:0]                                 av_s0_address,
  output logic  [3:0]                                  av_s0_byteEnable,
  output logic                                         av_s0_read,
  output logic                                         av_s0_write,
  output logic  [31:0]                                 av_s0_writeData,
  input  logic                                         av_s0_waitRequest,
  output logic                                         av_s0_beginBurstTransfer,
  output logic  [`CACHE_AVALON_BURST_COUNT_WIDTH-1:0]  av_s0_burstCount,
  input  logic  [31:0]                                 av_s0_readData,
  input  logic                                         av_s0_readDataValid,

  input  logic  [2:0]                                  ctr_cmd,
  output logic                                         ctr_cmd_ready,
  input  logic                                         ctr_isEnableCache,

  input  logic  [3:0]                                  rw_cmd,
  output logic                                         rw_cmd_ready,
  output logic                                         rw_isRequest,
  output logic  [31:0]                                 rw_rsp_data,
  input  logic  [31:0]                                 rw_last_av_s0_address,
  input  logic  [31:0]                                 rw_last_av_s0_writeData,
  input  logic  [3:0]                                  rw_last_av_s0_byteEnable,
  input  logic                                         rw_last_av_s0_read,
  input  logic                                         rw_last_av_s0_write,
  input  logic                                         rw_isHit,
  input  logic  [1:0]                                  rw_hitBlockNum,
  input  logic                                         rw_isHaveFreeBlock,
  input  logic  [1:0]                                  rw_freeBlockNum,
  /**/     
  output logic [DATA_RAM_ADDR_WIDTH-1:0]               data_ri_readAddress,
  output logic [1:0]                                   data_ri_rwChannel,
  input  logic [31:0]                                  data_ri_readData,
  output logic [DATA_RAM_ADDR_WIDTH-1:0]               data_ri_writeAddress,
  output logic [3:0]                                   data_ri_writeByteEnable,
  output logic                                         data_ri_writeEnable,
  output logic [31:0]                                  data_ri_writeData,
  /**/     
  output logic [TAG_RAM_ADDR_WIDTH-1:0]                tag_ri_readAddress,
  output logic [1:0]                                   tag_ri_readChannel,
  input  logic [31:0]                                  tag_ri_readData,
  output logic [TAG_RAM_ADDR_WIDTH-1:0]                tag_ri_writeAddress,
  output logic [1:0]                                   tag_ri_writeChannel,
  output logic                                         tag_ri_writeEnable,
  output logic [31:0]                                  tag_ri_writeData,
  /**/   
  output logic [DRE_RAM_ADDR_WIDTH-0:0]                dre_ri_readAddress,
  output logic [1:0]                                   dre_ri_readChannel,
  input  logic [7:0]                                   dre_ri_readData,
  input  logic [3:0]                                   dre_ri_readRe,
  output logic [DRE_RAM_ADDR_WIDTH-1:0]                dre_ri_writeAddress,
  output logic [1:0]                                   dre_ri_writeChannel,
  output logic                                         dre_ri_writeEnable,
  output logic [7:0]                                   dre_ri_writeData
);

/**************************************************************************
av从机s0的指令fifo
**************************************************************************/
/*fifo实例的参数*/
localparam AVALON_S0_CMD_FIFO_WIDTH     = $bits({
                                            av_s0_address,        
                                            av_s0_byteEnable,     
                                            av_s0_read,
                                            av_s0_write,          
                                            av_s0_writeData,
                                            av_s0_beginBurstTransfer,
                                            av_s0_burstCount
                                          });
localparam AVALON_S0_CMD_FIFO_DEPTH     = 2;
/*fifo的端口*/
wire                                    av_s0_cmd_fifo_full;
wire                                    av_s0_cmd_fifo_empty;
wire                                    av_s0_cmd_fifo_half;
wire                                    av_s0_cmd_fifo_write;
wire                                    av_s0_cmd_fifo_read;
wire [AVALON_S0_CMD_FIFO_WIDTH-1:0]     av_s0_cmd_fifo_writeData;
wire [AVALON_S0_CMD_FIFO_WIDTH-1:0]     av_s0_cmd_fifo_readData;

/**************************************************************************
av_s0_cmd_fifo操作任务
**************************************************************************/
typedef struct
{
  reg                                      push;
  reg[31:0]                                address;
  reg[3:0]                                 byteEnable;
  reg                                      read;
  reg                                      write;
  reg[31:0]                                writeData;
  reg                                      beginBurstTransfer;
  reg[`CACHE_AVALON_BURST_COUNT_WIDTH-1:0] burstCount;
}av_cmd_fifo_port_type;

av_cmd_fifo_port_type av_s0_cmd_fifo_port;

assign {av_s0_cmd_fifo_write,av_s0_cmd_fifo_writeData}={
                                      av_s0_cmd_fifo_port.push,
                                      av_s0_cmd_fifo_port.address,
                                      av_s0_cmd_fifo_port.byteEnable,
                                      av_s0_cmd_fifo_port.read,
                                      av_s0_cmd_fifo_port.write,
                                      av_s0_cmd_fifo_port.writeData,
                                      av_s0_cmd_fifo_port.beginBurstTransfer,
                                      av_s0_cmd_fifo_port.burstCount
                                    };

/*-------------------压入一读条指令-------------------*/
task av_cmd_fifo_push_read(
  output av_cmd_fifo_port_type                fifo_port,
  input[31:0]                                 address,
  input[3:0]                                  byteEnable,
  input                                       beginBurstTransfer=0,
  input[`CACHE_AVALON_BURST_COUNT_WIDTH-1:0]  burstCount=0
);
  fifo_port.push=1;
  fifo_port.address=address;
  fifo_port.writeData=0;
  fifo_port.byteEnable=byteEnable;
  fifo_port.read=1;
  fifo_port.write=0;
  fifo_port.beginBurstTransfer=beginBurstTransfer;
  fifo_port.burstCount=burstCount;
endtask
/*-------------------压入一写条指令-------------------*/
task av_cmd_fifo_push_write(
  output av_cmd_fifo_port_type                fifo_port,
  input[31:0]                                 address,
  input[3:0]                                  byteEnable,
  input[31:0]                                 writeData,
  input                                       beginBurstTransfer=0,
  input[`CACHE_AVALON_BURST_COUNT_WIDTH-1:0]  burstCount=0
);
  fifo_port.push=1;
  fifo_port.address=address;
  fifo_port.byteEnable=byteEnable;
  fifo_port.read=0;
  fifo_port.write=1;
  fifo_port.writeData=writeData;
  fifo_port.beginBurstTransfer=beginBurstTransfer;
  fifo_port.burstCount=burstCount;
endtask
/*-------------------压入一读or写条指令-------------------*/
task av_cmd_fifo_push_read_write(
  output av_cmd_fifo_port_type                fifo_port,
  input[31:0]                                 address,
  input[3:0]                                  byteEnable,
  input                                       read,
  input                                       write,
  input[31:0]                                 writeData,
  input                                       beginBurstTransfer=0,
  input[`CACHE_AVALON_BURST_COUNT_WIDTH-1:0]  burstCount=0
);
  fifo_port.push=1;
  fifo_port.address=address;
  fifo_port.byteEnable=byteEnable;
  fifo_port.read=read;
  fifo_port.write=write;
  fifo_port.writeData=writeData;
  fifo_port.beginBurstTransfer=beginBurstTransfer;
  fifo_port.burstCount=burstCount;
endtask
/*-------------------压入一条空指令-------------------*/
task av_cmd_fifo_push_nop(
  output av_cmd_fifo_port_type                fifo_port
);
  fifo_port.push=0;
  fifo_port.address=0;
  fifo_port.byteEnable=0;
  fifo_port.read=0;
  fifo_port.write=0;
  fifo_port.writeData=0;
  fifo_port.beginBurstTransfer=0;
  fifo_port.burstCount=0;
endtask
/**************************************************************************
从dre ram中读出的可读信息的fifo
**************************************************************************/
localparam READ_BYTE_EN_FIFO_WIDTH      = 4;
localparam READ_BYTE_EN_FIFO_DEPTH      = 4;
wire                                    read_byte_en_fifo_full;
wire                                    read_byte_en_fifo_empty;
wire                                    read_byte_en_fifo_half;
wire                                    read_byte_en_fifo_write;
wire                                    read_byte_en_fifo_read;
wire [READ_BYTE_EN_FIFO_WIDTH-1:0]      read_byte_en_fifo_writeData;
wire [READ_BYTE_EN_FIFO_WIDTH-1:0]      read_byte_en_fifo_readData;

/**************************************************************************
其它wire与reg
**************************************************************************/
reg                       is_need_modific_tag;
reg[31:0]                 modific_tag;
wire                      isDirtyBlock;                               /*是否为脏块*/
wire [TAG_ADDR_WIDTH-1:0] tag_ri_read_block_addr;                                 /*块标签*/
reg  [1:0]                replaceFIFO[2**TAG_RAM_ADDR_WIDTH-1:0];     /*替换FIFO,其实就是一个计数器*/
reg  [1:0]                rwChannel;                                  /*读通道*/
reg  [31:0]               readAddress;                                /*读地址*/
reg  [31:0]               writeAddress;                               /*写地址*/
reg                       is_read_addr_change;                        /*读地址变化*/
reg                       is_read_data_valid;                         /*读数据有效*/
reg  [7:0]                count_a,count_b,count_c;
reg  [31:0]               address_a,address_b;

/**************************************************************************
连线
**************************************************************************/

assign read_byte_en_fifo_writeData      = dre_ri_readRe;
assign read_byte_en_fifo_read           = data_ri_writeEnable;
assign read_byte_en_fifo_write          = is_read_data_valid;

assign isDirtyBlock                 =     tag_ri_readData[TAG_ADDR_WIDTH+1];
assign tag_ri_read_block_addr       =     tag_ri_readData[TAG_ADDR_WIDTH-1:0];
assign data_ri_readAddress          =     readAddress[DATA_RAM_ADDR_WIDTH+1:2];
assign data_ri_writeAddress         =     writeAddress[DATA_RAM_ADDR_WIDTH+1:2];
assign data_ri_rwChannel            =     rwChannel;

assign tag_ri_readAddress           =     readAddress[TAG_RAM_ADDR_WIDTH+5:6];
assign tag_ri_writeAddress          =     writeAddress[TAG_RAM_ADDR_WIDTH+5:6];
assign tag_ri_readChannel           =     rwChannel;
assign tag_ri_writeChannel          =     rwChannel;

assign dre_ri_readAddress           =     readAddress[DRE_RAM_ADDR_WIDTH+2:2];
assign dre_ri_writeAddress          =     writeAddress[DRE_RAM_ADDR_WIDTH+2:3];
assign dre_ri_readChannel           =     rwChannel;
assign dre_ri_writeChannel          =     rwChannel;

assign rw_rsp_data                  =     av_s0_readData;

assign rw_isRequest                 =     ctr_cmd!=`cache_ctr_cmd_nop;

assign {
        av_s0_address,
        av_s0_byteEnable,
        av_s0_read,
        av_s0_write,
        av_s0_writeData,
        av_s0_beginBurstTransfer,
        av_s0_burstCount
}                                   =     av_s0_cmd_fifo_readData;
assign av_s0_cmd_fifo_read          =     !av_s0_waitRequest;

/*************************************************************************
状态机
*************************************************************************/
localparam  state_idle                 =     4'd0,
            state_waitReadIODone       =     4'd1,
            state_waitWriteIODone      =     4'd2,
            state_readMiss             =     4'd3,
            state_writeMiss            =     4'd4,
            state_writeBack            =     4'd5,
            state_readIn               =     4'd6,
            state_clearRe              =     4'd7,
            state_writeBackAll         =     4'd8,
            state_clearAll             =     4'd9,
            state_handleCtrCmd         =     4'd10,
            state_end_handle_read_miss =     4'd11,
            state_init                 =     4'd12;
reg[3:0] state,return_state;

wire end_state_waitReadIODone ;
wire end_state_waitWriteIODone;
wire end_state_writeBack;
wire end_state_readIn;
wire end_state_clearRe;
wire end_state_init;

assign end_state_waitReadIODone  =av_s0_cmd_fifo_empty&&(!av_s0_waitRequest||!av_s0_read)&&av_s0_readDataValid;
assign end_state_waitWriteIODone =av_s0_cmd_fifo_empty&&!av_s0_waitRequest;
assign end_state_writeBack       =av_s0_cmd_fifo_empty&&(count_c>=8'd16);
assign end_state_readIn          =av_s0_cmd_fifo_empty&&(count_c>=8'd16);
assign end_state_clearRe         =(count_a>=8'd7);
assign end_state_init            =(count_a<2**TAG_RAM_ADDR_WIDTH*4);
/*第一段*/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    state<=state_idle;
  end
  else begin
    case(state)
      state_idle:begin
          case(rw_cmd)
            `cache_rw_cmd_iorw:     state <= rw_last_av_s0_read ?state_waitReadIODone :  state_waitWriteIODone;
            `cache_rw_cmd_rb:       state <= rw_last_av_s0_read ?state_readMiss       :  state_writeMiss;
            `cache_rw_handleCtrCmd: state <= state_handleCtrCmd;
            default:state<=state_idle;
          endcase
        end
      state_waitReadIODone:begin
          if(end_state_waitReadIODone) begin
            state<=state_idle;
          end
        end
      state_waitWriteIODone:begin
          if(end_state_waitWriteIODone) begin
            state<=state_idle;
          end
        end
      state_readMiss:begin
          if(rw_isHit) begin
            state<=state_readIn;
            
          end
          else begin
            state<=isDirtyBlock?state_writeBack:state_readIn;
          end
        end
      state_writeMiss:begin
          state<=isDirtyBlock?state_writeBack:state_clearRe;
        end
      state_writeBack:begin
          if(end_state_writeBack) begin
            state<=return_state;
          end
        end
      state_readIn:begin
          if(end_state_readIn) begin
            state<=state_end_handle_read_miss;
          end
        end
      state_clearRe:begin
          if(end_state_clearRe) begin
            state<=state_idle;
          end
        end
      state_writeBackAll:begin

        end
      state_clearAll:begin

        end
      state_end_handle_read_miss:begin
          state<=state_idle;
        end
      state_handleCtrCmd:begin
          case(ctr_cmd)
            `cache_ctr_cmd_init:begin
                state<=state_init;
              end
             default:begin
                state<=state_idle;
              end
          endcase
        end
      state_init:begin
          if(end_state_init) begin
            state<=state_init;
          end
        end
      default:begin
        end
    endcase
  end
end

always @(posedge clk or negedge rest) begin
  if(!rest) begin
    data_ri_writeEnable<=1'd0;
    tag_ri_writeEnable<=1'd0;
    dre_ri_writeEnable<=1'd0;
    is_read_addr_change<=1'd0;
    is_read_data_valid<=1'd0;
    av_cmd_fifo_push_nop(av_s0_cmd_fifo_port);
  end
  else begin
    case(state)
      state_idle:begin
          state_idle_handle();
        end
      state_waitReadIODone:begin
          av_cmd_fifo_push_nop(av_s0_cmd_fifo_port);
        end
      state_waitWriteIODone:begin
          av_cmd_fifo_push_nop(av_s0_cmd_fifo_port);
        end
      state_readMiss,state_writeMiss:begin
          state_read_write_miss_handle();
        end
      state_writeBack:begin
          /*写回处理*/
          state_writeBack_handle();
        end
      state_readIn:begin
          /*读入处理*/
          state_readIn_handle();
        end
      state_clearRe:begin
          /*清除可读信息*/
          state_clearRe_handle();
        end
      state_writeBackAll:begin
          /*写回所有cache块*/
          /*state_clearRe();*/
        end
      state_clearAll:begin
          /*写回所有cache块,并清除所有可读信息*/
          /*state_clearAll*/
        end
      state_handleCtrCmd:begin
        end
      state_init:begin
          state_init_handle();
        end
      default:begin
        end  
    endcase
  end
end

always @(*) begin
  case (state)
    state_idle:begin
        rw_cmd_ready=1'd0;
      end
    state_waitReadIODone:begin
        rw_cmd_ready=end_state_waitReadIODone;
      end
    state_waitWriteIODone:begin
        rw_cmd_ready=end_state_waitWriteIODone;
      end
    state_clearRe:begin
        rw_cmd_ready=end_state_clearRe;
      end
    state_end_handle_read_miss:begin
        rw_cmd_ready<=1'd1;
      end
    default:begin
        rw_cmd_ready=1'd0;
      end
  endcase
end

/******************************************************************************************
空闲处理任务
******************************************************************************************/
task state_idle_handle();
  case(rw_cmd)
    `cache_rw_cmd_rb:begin
        /*没有命中,且没用空块了,开始淘汰*/
        if(!rw_isHit&&!rw_isHaveFreeBlock) begin
          replaceFIFO[rw_last_av_s0_address[TAG_RAM_ADDR_WIDTH+5:6]]<=
            replaceFIFO[rw_last_av_s0_address[TAG_RAM_ADDR_WIDTH+5:6]]+2'd1;
        end
          return_state<=rw_last_av_s0_read?state_readIn:state_clearRe;
      end
    `cache_rw_cmd_iorw:begin
        /*将rw模块收到的IO读写请求发送到总线上*/
        av_cmd_fifo_push_read_write(
          .fifo_port  (av_s0_cmd_fifo_port      ),
          .address    (rw_last_av_s0_address    ),
          .byteEnable (rw_last_av_s0_byteEnable ),
          .read       (rw_last_av_s0_read       ),
          .write      (rw_last_av_s0_write      ),
          .writeData  (rw_last_av_s0_writeData  )
        );
      end
    default:begin
      end
  endcase
  rwChannel<= rw_isHit            ? rw_hitBlockNum:
              rw_isHaveFreeBlock  ? rw_freeBlockNum:
                                    replaceFIFO[rw_last_av_s0_address[TAG_RAM_ADDR_WIDTH+5:6]];
  readAddress<=rw_last_av_s0_address;
  data_ri_writeEnable<=1'd0;
  tag_ri_writeEnable<=1'd0;
  dre_ri_writeEnable<=1'd0;
  is_read_addr_change<=1'd0;
endtask

/******************************************************************************************
读写缺失预处理任务
******************************************************************************************/
task state_read_write_miss_handle();
  is_need_modific_tag<=!rw_isHit;
  modific_tag<={{(32-TAG_ADDR_WIDTH-1){1'd0}},1'd1,rw_last_av_s0_address[31:31-TAG_ADDR_WIDTH+1]};
  count_a<=8'd0;
  count_b<=8'd0;
  count_c<=8'd0;
  is_read_addr_change<=1'd0;
  address_a<={tag_ri_read_block_addr,rw_last_av_s0_address[31-TAG_ADDR_WIDTH:0]};
  address_b<=rw_last_av_s0_address;
endtask

/******************************************************************************************
写回处理任务
第一次执行该任务前，需要完成如下几件事:
  1,count_a,count_b,count_c三个计数器清零,
  2,给出address_a(写入到存储器的地址)
  3,rwChannel修改为对应的通道
******************************************************************************************/
task state_writeBack_handle();
  /*改变内部SRAM读地址*/
  if(!(av_s0_write&&av_s0_waitRequest)&&(count_a<8'd16)) begin
    readAddress<=address_a+count_a*4;
    is_read_addr_change<=1'd1;
  end
  else begin
    is_read_addr_change<=1'd0;
  end
  /*将内部SRAM中读出的数据压到fifo中*/
  if(is_read_data_valid) begin
    av_cmd_fifo_push_write(
      .fifo_port          (av_s0_cmd_fifo_port  ),
      .address            (address_a+count_b*4  ),
      .byteEnable         (dre_ri_readRe        ),
      .writeData          (data_ri_readData     ),
      .beginBurstTransfer (count_b==8'd0        ),
      .burstCount         (16                   )
    );
  end
  else begin
    av_cmd_fifo_push_nop(av_s0_cmd_fifo_port);
  end
  /*当fifo满，并且av_s0_waitRequest为高的时候，表示上一次的数据没写入到fifo中，
    所以is_read_data_valid需要保持，反之则需要更新*/
  if(!(av_s0_cmd_fifo_full&&av_s0_waitRequest)) begin
    is_read_data_valid<=is_read_addr_change;
  end
  /*-----------------计数器控制--------------------------------------*/
  if(!end_state_writeBack) begin
    /*修改一次地址,count_a加一*/
    if(!(av_s0_write&&av_s0_waitRequest)&&(count_a<8'd16)) begin
      count_a++;
    end
    /*没向FIFO中压入一条写数据指令,count_b加一*/
    if(is_read_data_valid) begin
      count_b++;
    end
    /*每写一个数据count_c加一*/
    if(av_s0_write&&!av_s0_waitRequest) begin
      count_c++;
    end
  end
  else begin
    /*如果下一步需要进入到其它状态,全部清零*/
    count_a<=8'd0;
    count_b<=8'd0;
    count_c<=8'd0;
  end
endtask

/******************************************************************************************
读入处理任务
第一次执行该任务前，需要完成如下几件事:
  1,count_a,count_b,count_c三个计数器清零,
  2,给出address_b(写入到存储器的地址)
  3,rwChannel修改为对应的通道
最后一次执行完该任务后:
  需要在下一个时钟将
    data_ri_writeEnable
    tag_ri_writeEnable 
    dre_ri_writeEnable
  这三个寄存器置0
******************************************************************************************/
task state_readIn_handle();
  if(!read_byte_en_fifo_half&&rw_isHit&&(count_a<8'd16)) begin
    /*字节使能信号fifo占用还没过半，还能装，命中了(说明是因为byte不可读造成的，写cache块时不能覆
      盖原来的数据，所以需要考虑字节可读信号)*/
    readAddress<=address_b+count_a*4;
    /*地址改变了,置1*/
    is_read_addr_change<=1'd1;
  end
  else begin
    /*地址没有改变,置0*/
    is_read_addr_change<=1'd0;
  end
  if((!av_s0_cmd_fifo_full||av_s0_waitRequest)&&(count_b<8'd16)) begin
    /*总线指令fifo还能装,向fifo写读数据入指令*/
    av_cmd_fifo_push_read(
      .fifo_port          (av_s0_cmd_fifo_port  ),
      .address            (address_b+count_b*4  ),
      .byteEnable         (4'hf                 ),
      .beginBurstTransfer (count_b==8'd0        ),
      .burstCount         (8'd16                )
    );
  end
  else begin
    av_cmd_fifo_push_nop(av_s0_cmd_fifo_port);
  end
  if(av_s0_readDataValid) begin
    /*数据从总线读出来了，写入到cache块*/
    writeAddress<=address_b+count_c*4;
    /*data*/
    data_ri_writeByteEnable<=rw_isHit?~read_byte_en_fifo_readData:4'hf;
    data_ri_writeData<=av_s0_readData;
    data_ri_writeEnable <= 1'd1;
    /*tag*/
    tag_ri_writeData<={{(32-TAG_ADDR_WIDTH-1){1'd0}},1'd1,address_b[31:31-TAG_ADDR_WIDTH+1]};
    tag_ri_writeEnable  <= count_c==8'd0;
    /*dre*/
    dre_ri_writeData<=8'hff;
    dre_ri_writeEnable  <= 1'd1;
  end
  else begin
    data_ri_writeEnable <= 1'd0;
    tag_ri_writeEnable  <= 1'd0;
    dre_ri_writeEnable  <= 1'd0;
  end
  is_read_data_valid<=is_read_addr_change;
  /*-----------------计数器控制--------------------------------------*/
  if(!end_state_readIn) begin
    if(!read_byte_en_fifo_half&&rw_isHit&&(count_a<8'd16)) begin
      count_a++;
    end
    if((!av_s0_cmd_fifo_full||av_s0_waitRequest)&&(count_b<8'd16)) begin
      count_b++;
    end
    if(av_s0_readDataValid) begin
      count_c++;
    end
  end
  else begin
    readAddress<=rw_last_av_s0_address;
    /*如果下一步需要进入到其它状态,全部清零*/
    count_a<=8'd0;
    count_b<=8'd0;
    count_c<=8'd0;
  end
endtask
/******************************************************************************************
清除可读信息任务
第一次执行该任务前，需要完成如下几件事:
  1,count_a,count_b,count_c三个计数器清零,
  2,给出address_b(写入到存储器的地址)
  3,rwChannel修改为对应的通道
******************************************************************************************/
task state_clearRe_handle();
  writeAddress<=address_a+count_a*8;
  /*如果需要修改标签，则修改标签*/
  tag_ri_writeData<=modific_tag;
  tag_ri_writeEnable<=(count_a==8'd0)&&is_need_modific_tag;
  /*清除Readable info*/
  dre_ri_writeData<=8'd0;
  dre_ri_writeEnable<=count_a<8'd8;
  if(!end_state_clearRe) begin
    count_a++;
  end
  else begin
    readAddress<=rw_last_av_s0_address;
    count_a<=8'd0;
  end
endtask

task state_handleCtrCmd_handle();
  address_a<=0;
  count_a<=0;
endtask

task state_init_handle();
  {rwChannel,writeAddress}<={address_a+count_a*4}<<6;
  tag_ri_writeData<=0;
  tag_ri_writeEnable<=1'd1;
  count_a<=count_a+8'd1;
endtask


/******************************************************************************************
fifo_sync_bypass实例
******************************************************************************************/
/*-----av总线指令fifo------------------------*/
fifo_sync_bypass #(
  .WIDTH(AVALON_S0_CMD_FIFO_WIDTH),
  .DEPTH(AVALON_S0_CMD_FIFO_DEPTH)
)
fifo_sync_bypass_inst0_av_s0_cmd_fifo(
  .clk       (clk                      ),
  .rest      (rest                     ),
  .full      (av_s0_cmd_fifo_full      ),
  .empty     (av_s0_cmd_fifo_empty     ),
  .half      (av_s0_cmd_fifo_half      ),
  .write     (av_s0_cmd_fifo_write     ),
  .read      (av_s0_cmd_fifo_read      ),
  .writeData (av_s0_cmd_fifo_writeData ),
  .readData  (av_s0_cmd_fifo_readData  )
);
/*-----可读mask fifo------------------------*/
fifo_sync_bypass #(
  .WIDTH(READ_BYTE_EN_FIFO_WIDTH),
  .DEPTH(READ_BYTE_EN_FIFO_DEPTH)
)
fifo_sync_bypass_inst1_read_byten_en_fifo(
  .clk       (clk                         ),
  .rest      (rest                        ),
  .full      (read_byte_en_fifo_full      ),
  .empty     (read_byte_en_fifo_empty     ),
  .half      (read_byte_en_fifo_half      ),
  .write     (read_byte_en_fifo_write     ),
  .read      (read_byte_en_fifo_read      ),
  .writeData (read_byte_en_fifo_writeData ),
  .readData  (read_byte_en_fifo_readData  )
);

endmodule
