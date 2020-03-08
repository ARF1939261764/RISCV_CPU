`include "cache_define.sv"

module cache_rw #(
  parameter DATA_RAM_ADDR_WIDTH=9,
            TAG_RAM_ADDR_WIDTH=5,
            DRE_RAM_ADDR_WIDTH=8,
            TAG_ADDR_WIDTH=21
)(
  input                                    clk,
  input                                    rest,
  /*arb从机接口*/
  input       [31:0]                       arb_address,             /*读写地址*/
  input       [3:0]                        arb_byteEnable,          /*字节使能(读写均有效)*/
  input                                    arb_read,                /*读使能信号(读写使能信号不能同时为高电平)*/   
  output      [31:0]                       arb_readData,            /*读出的数据*/   
  input                                    arb_write,               /*写使能信号(读写使能信号不能同时为高电平)*/    
  input       [31:0]                       arb_writeData,           /*需要写入的数据*/  
  output                                   arb_waitRequest,         /*命令接受信号,为0表示接收了该条指令*/     
  output                                   arb_readDataValid,       /*数据有效信号*/
  output                                   arb_isEnableCache,       /*cache是否使能*/
  input                                    arb_bus_idle,            /*总线空闲,高电平表示总线空闲*/
  /**/  
  output      [31:0]                       ctr_address,             /*该信号输出至cache_ctr module,然后该模块返回一个信号表示这个地址是否为IO设备地址段的地址*/
  input                                    ctr_isIOAddrBlock,       /*ctr_address是否为IO设备地址段的地址*/      
  input                                    ctr_isEnableCache,       /*cache是否使能*/      
  
  input                                    ri_isRequest,            /*来自cache_ri模块,表示ri模块是否有待处理指令,也表示ri模块当前需要获得3块RAM的控制权*/
  output reg  [3:0]                        ri_cmd,                  /*输出到ri模块的命令*/
  input                                    ri_cmd_ready,            /*来自ri模块,表示命令是否处理完成*/
  input       [31:0]                       ri_rsp_data,             /*来自ri模块返回的数据*/
  output      [31:0]                       ri_last_arb_address,     /*向ri发出命令时表示rw模块接收到的地址*/
  output      [31:0]                       ri_last_arb_writeData,   /*向ri发出命令时表示rw模块接收到的数据*/
  output      [3:0]                        ri_last_arb_byteEnable,  /*向ri发出命令时表示rw模块接收到的字节使能信号*/
  output                                   ri_last_arb_read,        /*向ri发出命令时表示rw模块接收到的读使能信号*/
  output                                   ri_last_arb_write,       /*向ri发出命令时表示rw模块接收到的写使能信号*/
  output                                   ri_isHit,                /*是否命中*/
  output      [1:0]                        ri_hitBlockNum,          /*如果命中，命中的哪一块*/
  output                                   ri_isHaveFreeBlock,      /*是否还有空余的块*/
  output      [1:0]                        ri_freeBlockNum,         /*如果还有空块，哪一块是空的*/

  input       [DATA_RAM_ADDR_WIDTH-1:0]    data_ri_readAddress,     /*data ram的读地址线*/
  input       [1:0]                        data_ri_rwChannel,       /*读写通道(总共4个通道,4路)*/
  output      [31:0]                       data_ri_readData,        /*读出来的数据,一次读出32位*/
  input       [DATA_RAM_ADDR_WIDTH-1:0]    data_ri_writeAddress,    /*data ram的写地址线*/
  input       [3:0]                        data_ri_writeByteEnable, /*写字节使能*/
  input                                    data_ri_writeEnable,     /*写使能*/
  input       [31:0]                       data_ri_writeData,       /*需要写入的数据，一次写入32位*/

  input       [TAG_RAM_ADDR_WIDTH-1:0]     tag_ri_readAddress,      /*tag ram的读地址线*/
  input       [1:0]                        tag_ri_readChannel,      /*读通道*/
  output      [31:0]                       tag_ri_readData,         /*读出来的数据*/
  input       [TAG_RAM_ADDR_WIDTH-1:0]     tag_ri_writeAddress,     /*写地址*/
  input       [1:0]                        tag_ri_writeChannel,     /*写通道*/
  input                                    tag_ri_writeEnable,      /*写使能 */
  input       [31:0]                       tag_ri_writeData,        /*需要写入的数据*/

  input       [DRE_RAM_ADDR_WIDTH-0:0]     dre_ri_readAddress,      /*读地址*/
  input       [1:0]                        dre_ri_readChannel,      /*读通道*/
  output      [7:0]                        dre_ri_readData,         /*读出的数据(1次8bit)*/
  output      [3:0]                        dre_ri_readRe,
  input       [DRE_RAM_ADDR_WIDTH-1:0]     dre_ri_writeAddress,     /*写地址*/
  input       [1:0]                        dre_ri_writeChannel,     /*写数据*/
  input                                    dre_ri_writeEnable,      /*写使能*/
  input       [7:0]                        dre_ri_writeData         /*写数据(一次8bit)*/
);
/**************************************************************************
连接到实例module的wire
**************************************************************************/
wire                              sel;                          /*选择信号，值与arb_waitRequest绑定*/

wire [DATA_RAM_ADDR_WIDTH-1:0]    data_rw_readAddress;          /*读地址*/
wire [1:0]                        data_rw_rwChannel;            /*读通道*/
wire [31:0]                       data_rw_readData;             /*读出的数据*/
wire [DATA_RAM_ADDR_WIDTH-1:0]    data_rw_writeAddress;         /*写地址*/
wire [3:0]                        data_rw_writeByteEnable;      /*写字节使能*/
wire                              data_rw_writeEnable;          /*写使能*/
wire [31:0]                       data_rw_writeData;            /*写数据*/

wire [TAG_RAM_ADDR_WIDTH-1:0]     tag_rw_readAddress;           /*读地址*/
wire [TAG_RAM_ADDR_WIDTH-1:0]     tag_rw_writeAddress;          /*写地址*/
wire                              tag_rw_writeEnable;           /*写使能*/
wire [TAG_ADDR_WIDTH-1:0]         tag_rw_tag;                   /*需要对比的地址(高位地址),内部没有缓存的寄存器*/
wire                              tag_rw_isHit;                 /*数据的地址是否命中*/
wire [1:0]                        tag_rw_hitBlockNum;           /*如果命中,表示命中的是哪一个块*/
wire                              tag_rw_isHaveFreeBlock;
wire [1:0]                        tag_rw_freeBlockNum;

wire [DRE_RAM_ADDR_WIDTH-0:0]     dre_rw_readAddress;           /*读地址*/
wire [1:0]                        dre_rw_readChannel;           /*读通道*/
wire [3:0]                        dre_rw_readRe;                /*读出来的可读信息(一次4bit,分别表示4个字节是否可读)*/
wire [DRE_RAM_ADDR_WIDTH-1:0]     dre_rw_writeAddress;          /*写地址*/
wire [1:0]                        dre_rw_writeChannel;          /*写通道*/
wire                              dre_rw_writeEnable;           /*写使能*/
wire [3:0]                        dre_rw_writeRe;               /*写字节使能*/

/**************************************************************************
当前模块需要用到的reg、wire
**************************************************************************/
reg  [31:0]                       last_arb_address;             /*缓存一级*/
reg  [3:0]                        last_arb_byteEnable;
reg                               last_arb_read;
reg                               last_arb_write;
reg  [31:0]                       last_arb_writeData;

reg  [31:0]                       readBuff_arb_address;         /*再缓存一级*/
reg  [3:0]                        readBuff_arb_byteEnable;
reg                               readBuff_arb_write;
reg  [31:0]                       readBuff_arb_writeData;

reg                               last_isHit;
reg  [1:0]                        last_hitBlockNum;
reg                               last_isHaveFreeBlock;
reg  [1:0]                        last_freeBlockNum;

wire                              rw_waitRequest;               /*rw模块能否及时处理命令*/
wire                              ri_waitRequest;               /*ri模块是否在请求RAM的控制权,即ri模块是否需要处理来自ctr模块的命令*/
wire                              isCacheEn;                    /*cache是否使能*/
wire                              isIoAddr;                     /*是否是IO设备地址段的地址*/
wire                              isHit;                        /*给定地址是否命中*/
wire                              isRe;                         /*是否可读*/
wire                              isR;                          /*是否是读命令*/
wire                              isW;                          /*是否是写命令*/
wire                              isReadFault;                  /*读命令是否发生fault*/
wire                              isWriteFault;                 /*写命令是否发生fault*/
wire                              isFault;                      /*读写命令是否发生fault*/
wire                              isNeedSendCmdToRi;            /*是否需要向ri模块发生命令*/

wire[3:0]                         readableMask;                 /*可读掩码*/
/**************************************************************************
连线
**************************************************************************/
assign sel                     =  arb_waitRequest;

assign data_rw_readAddress     =  arb_address[DATA_RAM_ADDR_WIDTH+1:2];
assign data_rw_rwChannel       =  tag_rw_hitBlockNum;
assign data_rw_writeAddress    =  last_arb_address[DATA_RAM_ADDR_WIDTH+1:2];
assign data_rw_writeByteEnable =  last_arb_byteEnable;
assign data_rw_writeEnable     =  last_arb_write;
assign data_rw_writeData       =  last_arb_writeData;

assign tag_rw_readAddress      =  arb_address[DATA_RAM_ADDR_WIDTH+1:6];
assign tag_rw_writeAddress     =  last_arb_address[DATA_RAM_ADDR_WIDTH+1:6];
assign tag_rw_writeEnable      =  last_arb_write;
assign tag_rw_tag              =  last_arb_address[31:31-TAG_ADDR_WIDTH+1];

assign dre_rw_readAddress      =  arb_address[DATA_RAM_ADDR_WIDTH+2:2];
assign dre_rw_readChannel      =  tag_rw_hitBlockNum;
assign dre_rw_writeAddress     =  last_arb_address[DATA_RAM_ADDR_WIDTH+2:3];
assign dre_rw_writeChannel     =  tag_rw_hitBlockNum;
assign dre_rw_writeEnable      =  last_arb_write;
assign dre_rw_writeRe          =  last_arb_byteEnable;

assign ctr_address             =  arb_address;
assign arb_isEnableCache       =  isCacheEn;
assign arb_readData            =  (state==state_idle)||(ri_cmd!=`cache_rw_cmd_iorw)?{
                                    readBuff_arb_write&&readableMask[3]?readBuff_arb_writeData[31:24]:data_rw_readData[31:24],
                                    readBuff_arb_write&&readableMask[2]?readBuff_arb_writeData[23:16]:data_rw_readData[23:16],
                                    readBuff_arb_write&&readableMask[1]?readBuff_arb_writeData[15:8] :data_rw_readData[15:8] ,
                                    readBuff_arb_write&&readableMask[0]?readBuff_arb_writeData[7:0]  :data_rw_readData[7:0]  
                                  }:ri_rsp_data;
assign arb_readDataValid       =  (state==state_idle)?(last_arb_read&&!rw_waitRequest&&(last_state!=state_waitDone)):ri_cmd_ready&&last_arb_read;

assign isCacheEn               =  ctr_isEnableCache;
assign isIoAddr                =  ctr_isIOAddrBlock;
assign isHit                   =  tag_rw_isHit;
assign isRe                    =  (readableMask&last_arb_byteEnable)==last_arb_byteEnable;
assign isR                     =  last_arb_read;
assign isW                     =  last_arb_write;
assign readableMask            =  (readBuff_arb_write&&(readBuff_arb_address==last_arb_address))?(dre_rw_readRe|readBuff_arb_byteEnable):dre_rw_readRe;

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
assign arb_waitRequest         =  isNeedSendCmdToRi;

assign ri_last_arb_address     =  last_arb_address;
assign ri_last_arb_writeData   =  last_arb_writeData;
assign ri_last_arb_byteEnable  =  last_arb_byteEnable;
assign ri_last_arb_read        =  last_arb_read;
assign ri_last_arb_write       =  last_arb_write;
assign ri_isHit                =  last_isHit;
assign ri_hitBlockNum          =  last_hitBlockNum;
assign ri_isHaveFreeBlock      =  last_isHaveFreeBlock;
assign ri_freeBlockNum         =  last_freeBlockNum;

/**************************************************************************
缓存指令
**************************************************************************/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    {last_arb_address,last_arb_byteEnable,last_arb_read,last_arb_write,last_arb_writeData}<=0;
    {readBuff_arb_address,readBuff_arb_byteEnable,readBuff_arb_write,readBuff_arb_writeData}<=0;
    {last_isHit,last_hitBlockNum,last_isHaveFreeBlock,last_freeBlockNum}<=0;
  end
  else begin
    if(!arb_waitRequest) begin
      /*缓存一级,写数据时RAM从这里取数据*/
      {last_arb_address,last_arb_byteEnable,last_arb_read,last_arb_write,last_arb_writeData}
        <={arb_address,arb_byteEnable,arb_read,arb_write,arb_writeData};
      /*再缓存一级,读数据时如果条件满足则优先取这里的数据*/
      {readBuff_arb_address,readBuff_arb_byteEnable,readBuff_arb_write,readBuff_arb_writeData}
        <={last_arb_address,last_arb_byteEnable,last_arb_write,last_arb_writeData};
    end
    if(last_state==state_idle) begin
      /*缓存其它信号*/
      {last_isHit,last_hitBlockNum,last_isHaveFreeBlock,last_freeBlockNum}
        <={tag_rw_isHit,tag_rw_hitBlockNum,tag_rw_isHaveFreeBlock,tag_rw_freeBlockNum};
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
        else if(ri_waitRequest&&arb_bus_idle)begin
          ri_cmd<=`cache_rw_handleCtrCmd;
        end
        else begin
          ri_cmd<=`cache_rw_cmd_nop;
        end
      end      
    state_waitDone:begin
        ri_cmd<=ri_cmd_ready?`cache_rw_cmd_nop:ri_cmd;
      end 
    default:begin
        ri_cmd<=`cache_rw_cmd_nop;
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
  .rw_isHaveFreeBlock(tag_rw_isHaveFreeBlock),
  .rw_freeBlockNum(tag_rw_freeBlockNum),
  /*替换模块*/
  .ri_readAddress(tag_ri_readAddress),
  .ri_readChannel(tag_ri_readChannel),
  .ri_readData(tag_ri_readData),
  .ri_writeAddress(tag_ri_writeAddress),
  .ri_writeChannel(tag_ri_writeChannel),
  .ri_writeEnable(tag_ri_writeEnable),
  .ri_writeData(tag_ri_writeData)
);

/**************************************************************************
数据可读信息
**************************************************************************/
cache_rw_dre #(
  .ADDR_WIDTH(DRE_RAM_ADDR_WIDTH)
)
cache_rw_dre_inst0(
  .clk(clk),
  /*sel*/
  .sel(sel),
  /*读写模块*/
  .rw_readAddress(dre_rw_readAddress),
  .rw_readChannel(dre_rw_readChannel),
  .rw_readRe(dre_rw_readRe),
  .rw_writeAddress(dre_rw_writeAddress),
  .rw_writeChannel(dre_rw_writeChannel),
  .rw_writeEnable(dre_rw_writeEnable),
  .rw_writeRe(dre_rw_writeRe),
  /*替换模块*/
  .ri_readAddress(dre_ri_readAddress),
  .ri_readChannel(dre_ri_readChannel),
  .ri_readData(dre_ri_readData),
  .ri_readRe(dre_ri_readRe),
  .ri_writeAddress(dre_ri_writeAddress),
  .ri_writeChannel(dre_ri_writeChannel),
  .ri_writeEnable(dre_ri_writeEnable),
  .ri_writeData(dre_ri_writeData)
);

endmodule
