`include "define.v"

module cache_rw #(
  parameter SIZE=8*1024
)(
  clk,
  rest,
  /*s0从机接口*/
  s0_address,
  s0_byteEnable,
  s0_read,
  s0_readData,
  s0_write,
  s0_writeData,
  s0_waitRequest,
  s0_readDataValid,
  /**/
  ctr_address,
  ctr_isIOAddrBlock,
  ctr_isEnableCache,
  /**/
  ri_isCacheEnable,
  ri_isRequest,
  ri_cmd,
  ri_cmd_valid,
  ri_cmd_ready,
  ri_rsp_data,
  /**/
  data_ri_readAddress,
  data_ri_rwChannel,
  data_ri_readData,
  data_ri_writeAddress,
  data_ri_writeByteEnable,
  data_ri_writeEnable,
  data_ri_writeData,
  /**/
  tag_ri_readAddress,
  tag_ri_readChannel,
  tag_ri_readData,
  tag_ri_writeAddress,
  tag_ri_writeChannel,
  tag_ri_writeEnable,
  tag_ri_writeData,
  tag_ri_isHit,
  tag_ri_hitBlockNum,
  tag_ri_isHaveFreeBlock,
  tag_ri_freeBlockNum,
  /**/
  dre_ri_readAddress,
  dre_ri_readChannel,
  dre_ri_readData,
  dre_ri_writeAddress,
  dre_ri_writeChannel,
  dre_ri_writeEnable,
  dre_ri_writeData
);
input clk,rest;
/*s0从机接口*/
input       [31:0]                       s0_address;        
input       [3:0]                        s0_byteEnable;
input                                    s0_read;
output      [31:0]                       s0_readData;
input                                    s0_write;
input       [31:0]                       s0_writeData;
output                                   s0_waitRequest;
output                                   s0_readDataValid;
/**/
output      [31:0]                       ctr_address;
input                                    ctr_isIOAddrBlock;
input                                    ctr_isEnableCache;

output                                   ri_isCacheEnable;
input                                    ri_isRequest;
output reg  [3:0]                        ri_cmd;
output reg                               ri_cmd_valid;
input                                    ri_cmd_ready;
input       [31:0]                       ri_rsp_data;

input       [1:0]                        data_ri_readAddress;
input       [DATA_RAM_ADDR_WIDTH-1:0]    data_ri_rwChannel;
output      [31:0]                       data_ri_readData;
input       [DATA_RAM_ADDR_WIDTH-1:0]    data_ri_writeAddress;
input       [3:0]                        data_ri_writeByteEnable;
input                                    data_ri_writeEnable;
input       [31:0]                       data_ri_writeData;

input       [TAG_RAM_ADDR_WIDTH-1:0]     tag_ri_readAddress;
input       [1:0]                        tag_ri_readChannel;
output      [31:0]                       tag_ri_readData;
input       [TAG_RAM_ADDR_WIDTH-1:0]     tag_ri_writeAddress;
input       [1:0]                        tag_ri_writeChannel;
input                                    tag_ri_writeEnable;
input       [31:0]                       tag_ri_writeData;
output                                   tag_ri_isHit;
output      [1:0]                        tag_ri_hitBlockNum;
output                                   tag_ri_isHaveFreeBlock;
output      [1:0]                        tag_ri_freeBlockNum;

input       [DRE_RAM_ADDR_WIDTH-0:0]     dre_ri_readAddress;
input                                    dre_ri_readChannel;
output      [7:0]                        dre_ri_readData;
input       [DRE_RAM_ADDR_WIDTH-1:0]     dre_ri_writeAddress;
input       [1:0]                        dre_ri_writeChannel;
input                                    dre_ri_writeEnable;
input       [7:0]                        dre_ri_writeData;      

/**************************************************************************
function:计算数据位宽
**************************************************************************/
function integer log2;
	input integer num;
	begin
		log2=0;
		while(2**log2<num) begin
			log2=log2+1;
		end
	end
endfunction

/**************************************************************************
width
**************************************************************************/
localparam DATA_RAM_ADDR_WIDTH=log2(SIZE/(32/8*4));

localparam TAG_RAM_ADDR_WIDTH=DATA_RAM_ADDR_WIDTH-4;

localparam DRE_RAM_ADDR_WIDTH=log2(SIZE/32)+1;

localparam TAG_ADDR_WIDTH=32-(DATA_RAM_ADDR_WIDTH+2);

/**************************************************************************
连接到实例module的wire
**************************************************************************/
wire                              sel;/*选择信号*/

wire [DATA_RAM_ADDR_WIDTH-1:0]    data_rw_readAddress;
wire [1:0]                        data_rw_rwChannel;
wire [31:0]                       data_rw_readData;
wire [DATA_RAM_ADDR_WIDTH-1:0]    data_rw_writeAddress;
wire [3:0]                        data_rw_writeByteEnable;
wire                              data_rw_writeEnable;
wire [31:0]                       data_rw_writeData;

wire [TAG_RAM_ADDR_WIDTH-1:0]     tag_rw_readAddress;
wire [TAG_RAM_ADDR_WIDTH-1:0]     tag_rw_writeAddress;
wire                              tag_rw_writeEnable;
wire [TAG_ADDR_WIDTH-1:0]         tag_rw_tag;/*需要对比的标签(高位地址)*/
wire                              tag_rw_isHit;
wire [1:0]                        tag_rw_hitBlockNum;

wire [DRE_RAM_ADDR_WIDTH-0:0]     dre_rw_readAddress;
wire [1:0]                        dre_rw_readChannel;
wire [3:0]                        dre_rw_readRe;
wire [DRE_RAM_ADDR_WIDTH-1:0]     dre_rw_writeAddress;
wire [1:0]                        dre_rw_writeChannel;
wire                              dre_rw_writeEnable;
wire [3:0]                        dre_rw_writeByteEnable;

/**************************************************************************
当前模块需要用到的reg、wire
**************************************************************************/
reg  [31:0]                       last_s0_address;
reg  [3:0]                        last_s0_byteEnable;
reg                               last_s0_read;
reg                               last_s0_write;
reg  [31:0]                       last_s0_writeData;

reg  [31:0]                       readBuff_s0_address;
reg  [3:0]                        readBuff_s0_byteEnable;
reg                               readBuff_s0_write;
reg  [31:0]                       readBuff_s0_writeData;

wire                              rw_waitRequest;
wire                              ri_waitRequest;
wire                              isCacheEn;
wire                              isIoAddr;
wire                              isHit;
wire                              isRe;
wire                              isR;
wire                              isW;
wire                              isReadFault;
wire                              isWriteFault;
wire                              isFault;
wire                              isNeedSendCmdToRi;

wire[3:0]                         readMask;             
/**************************************************************************
连线
**************************************************************************/
assign sel                     =  s0_waitRequest;

assign data_rw_readAddress     =  s0_address[DATA_RAM_ADDR_WIDTH+1:2];
assign data_rw_rwChannel       =  tag_rw_hitBlockNum;
assign data_rw_writeAddress    =  last_s0_address[DATA_RAM_ADDR_WIDTH+1:2];
assign data_rw_writeByteEnable =  last_s0_byteEnable;
assign data_rw_writeEnable     =  last_s0_write;
assign data_rw_writeData       =  last_s0_writeData;

assign tag_rw_readAddress      =  s0_address[DATA_RAM_ADDR_WIDTH+1:6];
assign tag_rw_writeAddress     =  last_s0_address[DATA_RAM_ADDR_WIDTH+1:6];
assign tag_rw_writeEnable      =  last_s0_write;
assign tag_rw_tag              =  last_s0_address[31:31-TAG_ADDR_WIDTH+1];

assign dre_rw_readAddress      =  s0_address[DATA_RAM_ADDR_WIDTH+2:2];
assign dre_rw_readChannel      =  tag_rw_hitBlockNum;
assign dre_rw_writeAddress     =  last_s0_address[DATA_RAM_ADDR_WIDTH+2:3];
assign dre_rw_writeChannel     =  tag_rw_hitBlockNum;
assign dre_rw_writeEnable      =  last_s0_write;
assign dre_rw_writeByteEnable  =  last_s0_byteEnable;

assign ctr_address             =  s0_address;
assign ri_isCacheEnable        =  isCacheEn;
assign s0_readData             =  (state==state_idle)?{
                                    readBuff_s0_write&&readMask[3]?readBuff_s0_writeData[31:24]:data_rw_readData[31:24],
                                    readBuff_s0_write&&readMask[2]?readBuff_s0_writeData[23:16]:data_rw_readData[23:16],
                                    readBuff_s0_write&&readMask[1]?readBuff_s0_writeData[15:8] :data_rw_readData[15:8] ,
                                    readBuff_s0_write&&readMask[0]?readBuff_s0_writeData[7:0]  :data_rw_readData[7:0]  
                                  }:ri_rsp_data;
assign s0_readDataValid        =  (state==state_idle)?(last_s0_read&&!rw_waitRequest&&(last_state!=state_waitDone)):ri_cmd_ready&&last_s0_read;

assign isCacheEn               =  ctr_isEnableCache;
assign isIoAddr                =  ctr_isIOAddrBlock;
assign isHit                   =  tag_rw_isHit;
assign isRe                    =  (readMask&last_s0_byteEnable)==last_s0_byteEnable;
assign isR                     =  last_s0_read;
assign isW                     =  last_s0_write;
assign readMask                =  (readBuff_s0_write&&(readBuff_s0_address==last_s0_address))?(dre_rw_readRe|readBuff_s0_byteEnable):dre_rw_readRe;

assign isReadFault             =  isR             &&
                                  (
                                    isIoAddr      ||
                                    (!isHit)      ||
                                    (!isRe)
                                  );
assign isWriteFault            =  isW             &&
                                  (
                                    isIoAddr      ||
                                    (!isHit)
                                  );
assign isFault                 =  isReadFault||isWriteFault;

assign rw_waitRequest          =  (isFault||(state!=state_idle))&&
                                  (~((state==state_idle)&&(last_state==state_waitDone)));
assign ri_waitRequest          =  ri_isRequest;
assign isNeedSendCmdToRi       =  rw_waitRequest||ri_waitRequest;
assign s0_waitRequest          =  isNeedSendCmdToRi;

/**************************************************************************
缓存指令
**************************************************************************/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    {last_s0_address,last_s0_byteEnable,last_s0_read,last_s0_write,last_s0_writeData}<=0;
    {readBuff_s0_address,readBuff_s0_byteEnable,readBuff_s0_write,readBuff_s0_writeData}<=0;
  end
  else begin
    if(!s0_waitRequest) begin
      /*缓存一级,写数据时RAM从这里取数据*/
      {last_s0_address,last_s0_byteEnable,last_s0_read,last_s0_write,last_s0_writeData}
        <={s0_address,s0_byteEnable,s0_read,s0_write,s0_writeData};
      /*再缓存一级,读数据时如果条件满足则优先取这里的数据*/
      {readBuff_s0_address,readBuff_s0_byteEnable,readBuff_s0_write,readBuff_s0_writeData}
        <={last_s0_address,last_s0_byteEnable,last_s0_write,last_s0_writeData};
    end
  end
end

/**************************************************************************
状态机
**************************************************************************/
localparam state_idle=1'd0,
           state_waitDone=1'd1;
reg state,last_state;
/*第一段*/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    state<=state_idle;
    last_state<=state_idle;
  end
  else begin
    last_state<=state;
    case (state)
      state_idle:begin
          state<=isNeedSendCmdToRi?state_waitDone:state_idle;
        end
      state_waitDone:begin
          state<=ri_cmd_ready?state_idle:state_waitDone;
        end 
      default:begin
          state<=state_idle;
        end
    endcase
  end
end
/*第二段*/
always @(posedge clk) begin
  case (state)
    state_idle:begin
        if(rw_waitRequest) begin
          ri_cmd<=isIoAddr?`cache_rw_cmd_iorw:`cache_rw_cmd_rb;
        end
        else if(ri_waitRequest)begin
          ri_cmd<=`cache_rw_handleCtrCmd;
        end
        else begin
          ri_cmd<=`cache_rw_cmd_nop;
        end
        ri_cmd_valid<=isNeedSendCmdToRi?1'd1:1'd0;
      end      
    state_waitDone:begin
        ri_cmd_valid<=ri_cmd_ready?1'd0:1'd1;
      end 
    default:begin
        ri_cmd_valid<=1'd0;
      end
  endcase
end

/**************************************************************************
数据
**************************************************************************/
cache_rw_data #(
  .ADDR_WIDTH(DATA_RAM_ADDR_WIDTH)
)
cache_rw_data_inst0(
  .clk(clk),
   /*选择信号*/
  .sel(sel),
   /*读写模块*/
  .rw_readAddress(data_rw_readAddress),
  .rw_rwChannel(data_rw_rwChannel),
  .rw_readData(data_rw_readData),
  .rw_writeAddress(data_rw_writeAddress),
  .rw_writeByteEnable(data_rw_writeByteEnable),
  .rw_writeEnable(data_rw_writeEnable),
  .rw_writeData(data_rw_writeData),
   /*替换模块*/
  .ri_readAddress(data_ri_readAddress),
  .ri_rwChannel(data_ri_rwChannel),
  .ri_readData(data_ri_readData),
  .ri_writeAddress(data_ri_writeAddress),
  .ri_writeByteEnable(data_ri_writeByteEnable),
  .ri_writeEnable(data_ri_writeEnable),
  .ri_writeData(data_ri_writeData)
);

/**************************************************************************
cache块信息
**************************************************************************/
cache_rw_tag #(
  .ADDR_WIDTH(TAG_RAM_ADDR_WIDTH),
  .TAG_ADDR_WIDTH(TAG_ADDR_WIDTH)
)
cache_rw_tag_inst0(
  .clk(clk),
  /*选择信号*/
  .sel(sel),
  /*读写模块*/
  .rw_readAddress(tag_rw_readAddress),
  .rw_writeAddress(tag_rw_writeAddress),
  .rw_writeEnable(tag_rw_writeEnable),
  .rw_tag(tag_rw_tag),/*需要对比的标签(高位地址)*/
  .rw_isHit(tag_rw_isHit),
  .rw_hitBlockNum(tag_rw_hitBlockNum),
  /*替换模块*/
  .ri_readAddress(tag_ri_readAddress),
  .ri_readChannel(tag_ri_readChannel),
  .ri_readData(tag_ri_readData),
  .ri_writeAddress(tag_ri_writeAddress),
  .ri_writeChannel(tag_ri_writeChannel),
  .ri_writeEnable(tag_ri_writeEnable),
  .ri_writeData(tag_ri_writeData),
  .ri_isHit(tag_ri_isHit),
  .ri_hitBlockNum(tag_ri_hitBlockNum),
  .ri_isHaveFreeBlock(tag_ri_isHaveFreeBlock),
  .ri_freeBlockNum(tag_ri_freeBlockNum)
);

/**************************************************************************
数据可读信息
**************************************************************************/
cache_rw_dre #(
  .ADDR_WIDTH(DRE_RAM_ADDR_WIDTH)
)
cache_rw_dre_inst0(
  .clk(clk),
  .sel(sel),
  .rw_readAddress(dre_rw_readAddress),
  .rw_readChannel(dre_rw_readChannel),
  .rw_readRe(dre_rw_readRe),
  .rw_writeAddress(dre_rw_writeAddress),
  .rw_writeChannel(dre_rw_writeChannel),
  .rw_writeEnable(dre_rw_writeEnable),
  .rw_writeByteEnable(dre_rw_writeByteEnable),

  .ri_readAddress(dre_ri_readAddress),
  .ri_readChannel(dre_ri_readChannel),
  .ri_readData(dre_ri_readData),
  .ri_writeAddress(dre_ri_writeAddress),
  .ri_writeChannel(dre_ri_writeChannel),
  .ri_writeEnable(dre_ri_writeEnable),
  .ri_writeData(dre_ri_writeData)
);

endmodule
