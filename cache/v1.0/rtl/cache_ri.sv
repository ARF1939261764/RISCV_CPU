`include "cache_define.v"

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
其它wire与reg
**************************************************************************/
wire                  isDirtyBlock;                               /*是否为脏块*/
reg  [1:0]            replaceFIFO[2**TAG_RAM_ADDR_WIDTH-1:0];     /*替换FIFO,其实就是一个计数器*/
reg  [1:0]            rwChannel;                                  /*读通道*/
reg  [31:0]           readAddress;                                /*读地址*/
reg  [31:0]           writeAddress;                               /*写地址*/
reg                   is_read_addr_change;                        /*读地址变化*/
reg                   is_read_data_valid;                         /*读数据有效*/
reg  [7:0]            count_a,count_b;
reg  [31:0]           address_a,address_b;

/**************************************************************************
连线
**************************************************************************/

assign isDirtyBlock                 =     tag_ri_readData[TAG_ADDR_WIDTH+1];
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

assign {
        av_s0_address,
        av_s0_byteEnable,
        av_s0_read,
        av_s0_write,
        av_s0_writeData,
        av_s0_beginBurstTransfer,
        av_s0_burstCount
}=av_s0_cmd_fifo_readData;
assign av_s0_cmd_fifo_read=!av_s0_waitRequest;

/*************************************************************************
状态机
*************************************************************************/
localparam  state_idle              =     4'd0,
            state_waitReadIODone    =     4'd1,
            state_waitWriteIODone   =     4'd2,
            state_readMiss          =     4'd3,
            state_writeMiss         =     4'd4,
            state_writeBack         =     4'd5,
            state_readIn            =     4'd6,
            state_clearRe           =     4'd7,
            state_writeBackAll      =     4'd8,
            state_clearAll          =     4'd9,
            state_handleCtrCmd      =     4'd10;
reg[3:0] state;

wire end_state_waitReadIODone ;
wire end_state_waitWriteIODone;

assign end_state_waitReadIODone  =av_s0_cmd_fifo_full&&(!av_s0_waitRequest||!av_s0_read)&&av_s0_readDataValid;
assign end_state_waitWriteIODone =av_s0_cmd_fifo_full&&!av_s0_waitRequest;
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
          state<=end_state_waitReadIODone?state_idle:state_waitReadIODone;
        end
      state_waitWriteIODone:begin
          state<=end_state_waitWriteIODone?state_idle:state_waitWriteIODone;
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
          
        end
      state_readIn:begin

        end
      state_clearRe:begin

        end
      state_writeBackAll:begin

        end
      state_clearAll:begin

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
    av_cmd_fifo_push_nop(av_s0_cmd_fifo_port);
  end
  else begin
    case(state)
      state_idle:begin
          case(rw_cmd)
            `cache_rw_cmd_rb:begin
                /*没有命中,且没用空块了,开始淘汰*/
                if(!rw_isHit&&!rw_isHaveFreeBlock) begin
                  replaceFIFO[rw_last_av_s0_address[TAG_RAM_ADDR_WIDTH+5:6]]<=
                    replaceFIFO[rw_last_av_s0_address[TAG_RAM_ADDR_WIDTH+5:6]]+2'd1;
                end
              end
            `cache_rw_cmd_iorw:begin
                /*将rw模块收到的IO读写请求发送到总线上*/
                av_cmd_fifo_push_read_write(
                  .fifo_port  (av_s0_cmd_fifo_port),
                  .address    (rw_last_av_s0_address),
                  .byteEnable (rw_last_av_s0_byteEnable),
                  .read       (rw_last_av_s0_read),
                  .write      (rw_last_av_s0_write),
                  .writeData  (rw_last_av_s0_writeData)
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
        end
      state_waitReadIODone:begin
          av_cmd_fifo_push_nop(av_s0_cmd_fifo_port);
        end
      state_waitWriteIODone:begin
          av_cmd_fifo_push_nop(av_s0_cmd_fifo_port);
        end
      state_readMiss,state_writeMiss:begin
          count_a<=8'd0;
          count_b<=8'd0;
          is_read_addr_change<=1'd0;
          address_a<=rw_last_av_s0_address;
        end
      state_writeBack:begin
          /*改变内部SRAM读地址*/
          if(!(av_s0_write&&av_s0_waitRequest)&&(count_a<8'd16)) begin
            readAddress<=address_a+count_a*4;
            is_read_addr_change<=1'd1;
            count_a<=count_a+8'd1;
          end
          else begin
            is_read_addr_change<=1'd0;
          end
          /*将内部SRAM中读出的数据压到fifo中*/
          if(is_read_data_valid) begin
            av_cmd_fifo_push_write(
              .fifo_port(av_s0_cmd_fifo_port),
              .address(address_a+count_b*4),
              .byteEnable(dre_ri_readRe),
              .writeData(data_ri_readData),
              .beginBurstTransfer(count_b==8'd0),
              .burstCount(16)
            );
          end
          else begin
            av_cmd_fifo_push_nop(av_s0_cmd_fifo_port);
          end
          /*每写一个数据count_b加一*/
          if(av_s0_write&&!av_s0_waitRequest) begin
            count_b<=count_b+8'd1;
          end
          /*当fifo满，并且av_s0_waitRequest为高的时候，表示上一次的数据没写入到fifo中，
            所以is_read_data_valid需要保持，反之则需要更新*/
          if(!(av_s0_cmd_fifo_full&&av_s0_waitRequest)) begin
            is_read_data_valid<=is_read_addr_change;
          end
        end
      state_readIn:begin
          
        end
      state_clearRe:begin
        end
      state_writeBackAll:begin
        end
      state_clearAll:begin
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
    default:begin
        rw_cmd_ready=1'd0;
      end
  endcase
end

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

endmodule
