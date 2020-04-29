`include "cache_define.sv"

module cache_ri #(
  parameter DATA_RAM_ADDR_WIDTH=9,
            TAG_RAM_ADDR_WIDTH=5,
            DRE_RAM_ADDR_WIDTH=8,
            TAG_WIDTH =21,
            BLOCK_ADDR_WIDTH=6
)(
  /*时钟,复位*/
  input  logic                                         clk,
  input  logic                                         rest,
  /*avalon总线*/
  output logic  [31:0]                                 av_m0_address,
  output logic  [3:0]                                  av_m0_byteEnable,
  output logic                                         av_m0_read,
  output logic                                         av_m0_write,
  output logic  [31:0]                                 av_m0_writeData,
  input  logic                                         av_m0_waitRequest,
  output logic                                         av_m0_beginBurstTransfer,
  output logic  [`CACHE_AVALON_BURST_COUNT_WIDTH-1:0]  av_m0_burstCount,
  input  logic  [31:0]                                 av_m0_readData,
  input  logic                                         av_m0_readDataValid,

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
  output logic [DRE_RAM_ADDR_WIDTH-1:0]                dre_ri_readAddress,
  output logic [1:0]                                   dre_ri_readChannel,
  input  logic [7:0]                                   dre_ri_readData,
  input  logic [3:0]                                   dre_ri_readRe,
  output logic [DRE_RAM_ADDR_WIDTH-1:0]                dre_ri_writeAddress,
  output logic [1:0]                                   dre_ri_writeChannel,
  output logic                                         dre_ri_writeEnable,
  output logic [7:0]                                   dre_ri_writeData
);
localparam BLOCK_DEPTH=2**BLOCK_ADDR_WIDTH/4;

/**************************************************************************
av从机s0的指令fifo
**************************************************************************/
/*fifo实例的参数*/
localparam AVALON_S0_CMD_FIFO_DEPTH     = 2;
localparam AVALON_S0_CMD_FIFO_WIDTH     = $bits({
                                            av_m0_address,        
                                            av_m0_byteEnable,     
                                            av_m0_read,
                                            av_m0_write,          
                                            av_m0_writeData,
                                            av_m0_beginBurstTransfer,
                                            av_m0_burstCount
                                          });
/*fifo的端口*/
wire                                    av_m0_cmd_fifo_full;
wire                                    av_m0_cmd_fifo_empty;
wire                                    av_m0_cmd_fifo_half;
wire                                    av_m0_cmd_fifo_write;
wire                                    av_m0_cmd_fifo_read;
wire [AVALON_S0_CMD_FIFO_WIDTH-1:0]     av_m0_cmd_fifo_writeData;
wire [AVALON_S0_CMD_FIFO_WIDTH-1:0]     av_m0_cmd_fifo_readData;

/**************************************************************************
av_m0_cmd_fifo操作任务
**************************************************************************/
typedef struct
{
  logic                                       push;
  logic [31:0]                                address;
  logic [3:0]                                 byteEnable;
  logic                                       read;
  logic                                       write;
  logic [31:0]                                writeData;
  logic                                       beginBurstTransfer;
  logic [`CACHE_AVALON_BURST_COUNT_WIDTH-1:0] burstCount;
}av_cmd_fifo_port_type;

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
localparam READ_BYTE_EN_FIFO_WIDTH = 4;
localparam READ_BYTE_EN_FIFO_DEPTH = 8;
wire                               read_byte_en_fifo_full;
wire                               read_byte_en_fifo_empty;
wire                               read_byte_en_fifo_half;
wire                               read_byte_en_fifo_write;
wire                               read_byte_en_fifo_read;
wire [READ_BYTE_EN_FIFO_WIDTH-1:0] read_byte_en_fifo_writeData;
wire [READ_BYTE_EN_FIFO_WIDTH-1:0] read_byte_en_fifo_readData;

/**************************************************************************
其它wire与reg
**************************************************************************/
localparam                state_idle                 =     4'd0,
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
                          state_wait_count_to_zero   =     4'd11,
                          state_init                 =     4'd12,
                          state_end_handleCtrCmd     =     4'd13;
reg[3:0]                  state,return_state;
reg                       is_need_modific_tag;
reg[31:0]                 modific_tag;
wire                      isDirtyBlock;                               /*是否为脏块*/
wire [TAG_WIDTH-1:0]      tag_ri_read_block_addr;                     /*块标签*/
reg  [1:0]                replaceFIFO[2**TAG_RAM_ADDR_WIDTH-1:0];     /*替换FIFO,其实就是一个计数器*/
reg  [1:0]                rwChannel;                                  /*读通道*/
reg  [31:0]               readAddress;                                /*读地址*/
reg  [31:0]               writeAddress;                               /*写地址*/
reg                       is_read_addr_change;                        /*读地址变化:这里指读内部SRAM的*/
reg                       is_read_data_valid;                         /*读数据有效:这里指读内部SRAM的*/
reg  [15:0]               count_a,count_b,count_c,delay_count;        /*计数器*/
reg  [31:0]               address_a,address_b;
av_cmd_fifo_port_type     av_m0_cmd_fifo_port;

/**************************************************************************
连线
**************************************************************************/
assign read_byte_en_fifo_writeData  =     dre_ri_readRe;
assign read_byte_en_fifo_write      =     is_read_data_valid&&(state==state_readIn);
assign read_byte_en_fifo_read       =     data_ri_writeEnable;

assign isDirtyBlock                 =     tag_ri_readData[TAG_WIDTH]&&tag_ri_readData[TAG_WIDTH+1];/*被占用，并且被修改才能算是脏块*/
assign tag_ri_read_block_addr       =     tag_ri_readData[TAG_WIDTH-1:0];
assign data_ri_readAddress          =     readAddress[DATA_RAM_ADDR_WIDTH+1:2];
assign data_ri_writeAddress         =     writeAddress[DATA_RAM_ADDR_WIDTH+1:2];
assign data_ri_rwChannel            =     rwChannel;
assign data_ri_writeByteEnable      =     rw_isHit?~read_byte_en_fifo_readData:4'hf;

assign tag_ri_readAddress           =     readAddress[TAG_RAM_ADDR_WIDTH+BLOCK_ADDR_WIDTH-1:BLOCK_ADDR_WIDTH];
assign tag_ri_writeAddress          =     writeAddress[TAG_RAM_ADDR_WIDTH+BLOCK_ADDR_WIDTH-1:BLOCK_ADDR_WIDTH];
assign tag_ri_readChannel           =     rwChannel;
assign tag_ri_writeChannel          =     rwChannel;

assign dre_ri_readAddress           =     readAddress[DRE_RAM_ADDR_WIDTH+1:2];
assign dre_ri_writeAddress          =     writeAddress[DRE_RAM_ADDR_WIDTH+1:2];
assign dre_ri_readChannel           =     rwChannel;
assign dre_ri_writeChannel          =     rwChannel;

assign rw_rsp_data                  =     av_m0_readData;

assign rw_isRequest                 =     ctr_cmd!=`cache_ctr_cmd_nop;/*ctr模块发过来指令了*/

assign {
        av_m0_address,
        av_m0_byteEnable,
        av_m0_read,
        av_m0_write,
        av_m0_writeData,
        av_m0_beginBurstTransfer,
        av_m0_burstCount
} = av_m0_cmd_fifo_readData;
assign {
        av_m0_cmd_fifo_write,
        av_m0_cmd_fifo_writeData
} = {
  av_m0_cmd_fifo_port.push,
  av_m0_cmd_fifo_port.address,
  av_m0_cmd_fifo_port.byteEnable,
  av_m0_cmd_fifo_port.read,
  av_m0_cmd_fifo_port.write,
  av_m0_cmd_fifo_port.writeData,
  av_m0_cmd_fifo_port.beginBurstTransfer,
  av_m0_cmd_fifo_port.burstCount
};
assign av_m0_cmd_fifo_read          =     !av_m0_waitRequest;

/*************************************************************************
状态机
*************************************************************************/
wire end_state_waitReadIODone ;
wire end_state_waitWriteIODone;
wire end_state_writeBack;
wire end_state_readIn;
wire end_state_clearRe;
wire end_state_init;
wire end_state_wait_count_to_zero;

assign end_state_waitReadIODone      =av_m0_cmd_fifo_empty&&(!av_m0_waitRequest||!av_m0_read)&&av_m0_readDataValid;
assign end_state_waitWriteIODone     =av_m0_cmd_fifo_empty&&!av_m0_waitRequest;
assign end_state_writeBack           =count_c>=BLOCK_DEPTH;
assign end_state_readIn              =count_c>=BLOCK_DEPTH;
assign end_state_clearRe             =(count_a>=BLOCK_DEPTH/2);
assign end_state_init                =(count_a>=(2**TAG_RAM_ADDR_WIDTH*4-1));
assign end_state_wait_count_to_zero  =(delay_count==8'd0);
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
            state<=state_wait_count_to_zero;
          end
        end
      state_clearRe:begin
          if(end_state_clearRe) begin
            state<=state_wait_count_to_zero;
          end
        end
      state_writeBackAll:begin

        end
      state_clearAll:begin

        end
      state_wait_count_to_zero:begin
          if(end_state_wait_count_to_zero) begin
            state<=state_idle;
          end
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
            state<=state_end_handleCtrCmd;
          end
        end
      state_end_handleCtrCmd:begin
          state<=state_idle;
        end
      default:begin
        end
    endcase
  end
end

always @(posedge clk or negedge rest) begin
  if(!rest) begin:rest_block
    int i;
    data_ri_writeEnable<=1'd0;
    tag_ri_writeEnable<=1'd0;
    dre_ri_writeEnable<=1'd0;
    is_read_addr_change<=1'd0;
    is_read_data_valid<=1'd0;
    av_cmd_fifo_push_nop(av_m0_cmd_fifo_port);
    for(i=0;i<2**TAG_RAM_ADDR_WIDTH;i++) begin
      replaceFIFO[i]<=0;
    end
  end
  else begin
    case(state)
      state_idle:begin
          state_idle_handle();
        end
      state_waitReadIODone:begin
          av_cmd_fifo_push_nop(av_m0_cmd_fifo_port);
        end
      state_waitWriteIODone:begin
          av_cmd_fifo_push_nop(av_m0_cmd_fifo_port);
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
          state_handleCtrCmd_handle();
        end
      state_init:begin
          state_init_handle();
        end
      state_end_handleCtrCmd:begin
          state_end_handleCtrCmd_handle();
        end
      state_wait_count_to_zero:begin
          state_wait_count_to_zero_handle();
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
    state_wait_count_to_zero:begin
        rw_cmd_ready=end_state_wait_count_to_zero;
      end
    state_end_handleCtrCmd:begin
        rw_cmd_ready=1'd1;
      end
    default:begin
        rw_cmd_ready=1'd0;
      end
  endcase
end
always @(*) begin
  case(state)
    state_end_handleCtrCmd:begin
      ctr_cmd_ready=1'd1;
    end
    default:begin
      ctr_cmd_ready<=1'd0;
    end
  endcase
end
/******************************************************************************************
通过一个完整的地址获取对应cache块的首地址
******************************************************************************************/
function logic[31:0] get_cache_block_addr(input[31:0] address);
  return {address[31:BLOCK_ADDR_WIDTH],{BLOCK_ADDR_WIDTH{1'd0}}};
endfunction

/******************************************************************************************
空闲处理任务
******************************************************************************************/
task state_idle_handle();
  case(rw_cmd)
    `cache_rw_cmd_rb:begin
        /*没有命中,且没用空块了,开始淘汰*/
        if(!rw_isHit&&!rw_isHaveFreeBlock) begin
          replaceFIFO[rw_last_av_s0_address[TAG_RAM_ADDR_WIDTH+BLOCK_ADDR_WIDTH-1:BLOCK_ADDR_WIDTH]]<=
            replaceFIFO[rw_last_av_s0_address[TAG_RAM_ADDR_WIDTH+BLOCK_ADDR_WIDTH-1:BLOCK_ADDR_WIDTH]]+2'd1;
        end
          return_state<=rw_last_av_s0_read?state_readIn:state_clearRe;
      end
    `cache_rw_cmd_iorw:begin
        /*将rw模块收到的IO读写请求发送到总线上*/
        av_cmd_fifo_push_read_write(
          .fifo_port  (av_m0_cmd_fifo_port      ),
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
                                    replaceFIFO[rw_last_av_s0_address[TAG_RAM_ADDR_WIDTH+BLOCK_ADDR_WIDTH-1:BLOCK_ADDR_WIDTH]];
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
  modific_tag<=rw_last_av_s0_address[31:31-TAG_WIDTH+1]|(1<<TAG_WIDTH);
  count_a<=8'd0;
  count_b<=8'd0;
  count_c<=8'd0;
  is_read_addr_change<=1'd0;
  address_a<={tag_ri_read_block_addr,rw_last_av_s0_address[31-TAG_WIDTH:BLOCK_ADDR_WIDTH],{BLOCK_ADDR_WIDTH{1'd0}}};
  address_b<={rw_last_av_s0_address[31:BLOCK_ADDR_WIDTH],{BLOCK_ADDR_WIDTH{1'd0}}};
  //$display("address=%d\nstate=%s\nisHit=%d\nisHaveFreeBlock=%d\nrwChannel=%d\n",rw_last_av_s0_address,
  //                                                                            rw_last_av_s0_read?"readMiss":"writeMiss",
  //                                                                            rw_isHit,
  //                                                                            rw_isHaveFreeBlock,
  //                                                                            rwChannel);
endtask

/******************************************************************************************
写回处理任务
第一次执行该任务前，需要完成如下几件事:
  1,count_a,count_b,count_c三个计数器清零,
  2,给出address_a(写入到存储器的地址)
  3,rwChannel修改为对应的通道
******************************************************************************************/
task state_writeBack_handle();
  logic[31:0] block_addr;
  block_addr=get_cache_block_addr(address_a);
  /*改变内部SRAM读地址*/
  if(!(av_m0_write&&av_m0_waitRequest)&&(count_a<BLOCK_DEPTH)) begin
    readAddress<=block_addr+count_a*4;
    is_read_addr_change<=1'd1;
  end
  else begin
    is_read_addr_change<=1'd0;
  end
  /*当fifo满，并且av_m0_waitRequest为高的时候，表示上一次的数据没写入到fifo中，
    所以is_read_data_valid需要保持，反之则需要更新*/
  if(!av_m0_cmd_fifo_full||is_read_addr_change) begin
    is_read_data_valid<=is_read_addr_change;
  end
  /*-----------------计数器控制--------------------------------------*/
  if(!end_state_writeBack) begin
    /*修改一次地址,count_a加一*/
    if(!(av_m0_write&&av_m0_waitRequest)&&(count_a<BLOCK_DEPTH)) begin
      count_a++;
    end
    /*没向FIFO中压入一条写数据指令,count_b加一*/
    if(av_m0_cmd_fifo_write&&!av_m0_cmd_fifo_full&&(count_b<BLOCK_DEPTH)) begin
      count_b++;
    end
    /*每写一个数据count_c加一*/
    if(av_m0_write&&!av_m0_waitRequest) begin
      count_c++;
    end
  end
  else begin
    /*如果下一步需要进入到其它状态,全部清零*/
    av_cmd_fifo_push_nop(av_m0_cmd_fifo_port);
    count_a<=8'd0;
    count_b<=8'd0;
    count_c<=8'd0;
  end
  /*将内部SRAM中读出的数据压到fifo中*/
  if(!av_m0_cmd_fifo_full) begin
    if(is_read_data_valid&&!end_state_writeBack&&(count_b<BLOCK_DEPTH)) begin
      av_cmd_fifo_push_write(
        .fifo_port          (av_m0_cmd_fifo_port  ),
        .address            (block_addr+count_b*4 ),
        .byteEnable         (dre_ri_readRe        ),
        .writeData          (data_ri_readData     ),
        .beginBurstTransfer (count_b==8'd0        ),
        .burstCount         (BLOCK_DEPTH          )
      );
    end
    else begin
      av_cmd_fifo_push_nop(av_m0_cmd_fifo_port);
    end
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
  logic[31:0] block_addr;
  block_addr=get_cache_block_addr(address_b);
  if(!read_byte_en_fifo_half&&rw_isHit&&(count_a<BLOCK_DEPTH)) begin
    /*字节使能信号fifo占用还没过半，还能装，命中了(说明是因为byte不可读造成的，写cache块时不能覆
      盖原来的数据，所以需要考虑字节可读信号)*/
    readAddress<=block_addr+count_a*4;
    /*地址改变了,置1*/
    is_read_addr_change<=1'd1;
  end
  else begin
    /*地址没有改变,置0*/
    is_read_addr_change<=1'd0;
  end
  if(av_m0_readDataValid) begin
    /*数据从总线读出来了，写入到cache块*/
    writeAddress<=block_addr+count_c*4;
    /*data*/
    data_ri_writeData<=av_m0_readData;
    data_ri_writeEnable <= 1'd1;
    /*tag*/
    tag_ri_writeData<={{(32-TAG_WIDTH-1){1'd0}},1'd1,address_b[31:31-TAG_WIDTH+1]};
    tag_ri_writeEnable  <= (count_c==8'd0)&&is_need_modific_tag;
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
    if(!read_byte_en_fifo_half&&rw_isHit&&(count_a<BLOCK_DEPTH)) begin
      count_a++;
    end
    if(!av_m0_cmd_fifo_full&&av_m0_cmd_fifo_write&&(count_b<BLOCK_DEPTH)) begin
      count_b++;
    end
    if(av_m0_readDataValid) begin
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
  if(!av_m0_cmd_fifo_full) begin
    if(count_b<BLOCK_DEPTH) begin
      /*总线指令fifo还能装,向fifo写读数据入指令*/
      av_cmd_fifo_push_read(
        .fifo_port          (av_m0_cmd_fifo_port  ),
        .address            (block_addr+count_b*4 ),
        .byteEnable         (4'hf                 ),
        .beginBurstTransfer (count_b==8'd0        ),
        .burstCount         (BLOCK_DEPTH          )
      );
    end
    else begin
      av_cmd_fifo_push_nop(av_m0_cmd_fifo_port);
    end
  end
  delay_count<=1'd1;/*这里置1,因为下一个状态会进入到state_wait_count_to_zero状态,等一个时钟周期*/
endtask
/******************************************************************************************
清除可读信息任务
第一次执行该任务前，需要完成如下几件事:
  1,count_a,count_b,count_c三个计数器清零,
  2,给出address_b(写入到存储器的地址)
  3,rwChannel修改为对应的通道
******************************************************************************************/
task state_clearRe_handle();
  logic[31:0] block_addr;
  block_addr=get_cache_block_addr(address_a);
  writeAddress<=block_addr+count_a*8;
  /*如果需要修改标签，则修改标签*/
  tag_ri_writeData<=modific_tag;
  tag_ri_writeEnable<=(count_a==8'd0)&&is_need_modific_tag;
  /*清除Readable info*/
  dre_ri_writeData<=8'd0;
  dre_ri_writeEnable<=count_a<BLOCK_DEPTH/2;
  if(!end_state_clearRe) begin
    count_a++;
  end
  else begin
    delay_count<=8'd0;
    readAddress<=rw_last_av_s0_address;
    count_a<=8'd0;
  end
endtask
/******************************************************************************************
state_handleCtrCmd_handle
******************************************************************************************/
task state_handleCtrCmd_handle();
  address_a<=0;
  count_a<=0;
endtask
/******************************************************************************************
state_init_handle
******************************************************************************************/
task state_init_handle();
  logic[31:0] addr;
  addr={address_a+count_a}<<BLOCK_ADDR_WIDTH;
  {rwChannel,writeAddress[TAG_RAM_ADDR_WIDTH+BLOCK_ADDR_WIDTH-1:BLOCK_ADDR_WIDTH]}<=addr[TAG_RAM_ADDR_WIDTH+BLOCK_ADDR_WIDTH+1:BLOCK_ADDR_WIDTH];
  tag_ri_writeData<=32'h0;
  tag_ri_writeEnable<=1'd1;
  count_a<=count_a+8'd1;
endtask
/******************************************************************************************
state_end_handleCtrCmd_handle
******************************************************************************************/
task state_end_handleCtrCmd_handle();
  tag_ri_writeEnable<=1'd0;
endtask 
/******************************************************************************************
state_wait_count_to_zero_handle
******************************************************************************************/
task state_wait_count_to_zero_handle();
  delay_count--;
endtask


/******************************************************************************************
fifo_sync_bypass实例
******************************************************************************************/
/*-----av总线指令fifo------------------------*/
fifo_sync_bypass #(
  .WIDTH(AVALON_S0_CMD_FIFO_WIDTH),
  .DEPTH(AVALON_S0_CMD_FIFO_DEPTH)
)
fifo_sync_bypass_inst0_av_m0_cmd_fifo(
  .clk       (clk                      ),
  .rest      (rest                     ),
  .flush     (1'd0                     ),
  .full      (av_m0_cmd_fifo_full      ),
  .empty     (av_m0_cmd_fifo_empty     ),
  .half      (av_m0_cmd_fifo_half      ),
  .write     (av_m0_cmd_fifo_write     ),
  .read      (av_m0_cmd_fifo_read      ),
  .writeData (av_m0_cmd_fifo_writeData ),
  .readData  (av_m0_cmd_fifo_readData  ),
  .allData   ()
);
/*-----可读mask fifo------------------------*/
fifo_sync_bypass #(
  .WIDTH(READ_BYTE_EN_FIFO_WIDTH),
  .DEPTH(READ_BYTE_EN_FIFO_DEPTH)
)
fifo_sync_bypass_inst1_read_byten_en_fifo(
  .clk       (clk                         ),
  .rest      (rest                        ),
  .flush     (1'd0                        ),
  .full      (read_byte_en_fifo_full      ),
  .empty     (read_byte_en_fifo_empty     ),
  .half      (read_byte_en_fifo_half      ),
  .write     (read_byte_en_fifo_write     ),
  .read      (read_byte_en_fifo_read      ),
  .writeData (read_byte_en_fifo_writeData ),
  .readData  (read_byte_en_fifo_readData  ),
  .allData   ()
);

endmodule
