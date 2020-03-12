`timescale 1ns/100ps 

`include "cache_define.sv"

module cache_rw #(
  parameter DATA_RAM_ADDR_WIDTH=9,
            TAG_RAM_ADDR_WIDTH=5,
            DRE_RAM_ADDR_WIDTH=9,
            TAG_WIDTH=21,
            BLOCK_ADDR_WIDTH=6
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
  input                                    arb_bus_idle,            /*总线空闲,高电平表示ri模块可以使用总线,为什么rw模块要知道ri模块是否可以使用总线?因为这决定这rw模块能否给ri模块发生指令*/
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

  input       [DRE_RAM_ADDR_WIDTH-1:0]     dre_ri_readAddress,      /*读地址*/
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
logic                             sel;                          /*选择信号，值与arb_waitRequest绑定*/

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
wire [TAG_WIDTH-1:0]              tag_rw_tag;                   /*需要对比的地址(高位地址),内部没有缓存的寄存器*/
wire                              tag_rw_isHit;                 /*数据的地址是否命中*/
wire [1:0]                        tag_rw_hitBlockNum;           /*如果命中,表示命中的是哪一个块*/
wire                              tag_rw_isHaveFreeBlock;
wire [1:0]                        tag_rw_freeBlockNum;

wire [DRE_RAM_ADDR_WIDTH-1:0]     dre_rw_readAddress;           /*读地址*/
wire [1:0]                        dre_rw_readChannel;           /*读通道*/
wire [3:0]                        dre_rw_readRe;                /*读出来的可读信息(一次4bit,分别表示4个字节是否可读)*/
wire [DRE_RAM_ADDR_WIDTH-1:0]     dre_rw_writeAddress;          /*写地址*/
wire [1:0]                        dre_rw_writeChannel;          /*写通道*/
wire                              dre_rw_writeEnable;           /*写使能*/
wire [3:0]                        dre_rw_writeRe;               /*需要写入的字节使能信息*/

/**************************************************************************
状态机的状态
**************************************************************************/
localparam  state_idle=1'd0,
            state_waitDone=1'd1;
/**************************************************************************
当前模块需要用到的reg、wire
**************************************************************************/
reg                               state;                        /*状态机的状态寄存器，为啥要定义在这里，因为连线要用到(先定义后使用)*/
reg                               last_state;
reg  [31:0]                       last_arb_address;             /*缓存一级*/
reg  [3:0]                        last_arb_byteEnable;
reg                               last_arb_read;
reg                               last_arb_write;
reg  [31:0]                       last_arb_writeData;

reg                               last_isNeedSendCmdToRi;

reg  [31:0]                       readBuff_arb_address;         /*再缓存一级,这里缓存,是为了读一个刚写入的数据时避免冲突(如果读的数据正在写入,则从这里面读出那个数据)*/
reg  [3:0]                        readBuff_arb_byteEnable;
reg                               readBuff_arb_write;
reg  [31:0]                       readBuff_arb_writeData;

reg                               last_isHit;                   /*缓存一级,这里缓存，是因为当发生读写缺失、或者读写IO时，ri模块需要知道rw模块遇到了什么问题?是没命中,还是命中了,但是需要读的byte不可读*/
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
wire                              isWriteBuffHit;

wire[3:0]                         readableMask;                 /*可读掩码*/
/**************************************************************************
连线
**************************************************************************/
assign data_rw_readAddress     =  arb_address[DATA_RAM_ADDR_WIDTH+1:2];       /*[DATA_RAM_ADDR_WIDTH+1:2]是因为cache_rw_data模块中的RAM每个地址保存的字节数为4*/
assign data_rw_rwChannel       =  tag_rw_hitBlockNum;                         /*哪一路命中，读哪一路*/
assign data_rw_writeAddress    =  last_arb_address[DATA_RAM_ADDR_WIDTH+1:2];  /*同上,这里用的是缓冲寄存器的结果是因为第一个时钟周期用来查找对应的cache块了,第二个时钟周期才能写入,所以要缓冲一级*/
assign data_rw_writeByteEnable =  last_arb_byteEnable;
assign data_rw_writeEnable     =  last_arb_write&&!arb_waitRequest;
assign data_rw_writeData       =  last_arb_writeData;

assign tag_rw_readAddress      =  arb_address[TAG_RAM_ADDR_WIDTH + BLOCK_ADDR_WIDTH - 1:BLOCK_ADDR_WIDTH];
assign tag_rw_writeAddress     =  last_arb_address[TAG_RAM_ADDR_WIDTH + BLOCK_ADDR_WIDTH - 1:BLOCK_ADDR_WIDTH];
assign tag_rw_writeEnable      =  last_arb_write&&!arb_waitRequest;
assign tag_rw_tag              =  last_arb_address[31:31-TAG_WIDTH+1];

assign dre_rw_readAddress      =  arb_address[DRE_RAM_ADDR_WIDTH+1:2];
assign dre_rw_readChannel      =  tag_rw_hitBlockNum;
assign dre_rw_writeAddress     =  last_arb_address[DRE_RAM_ADDR_WIDTH+1:2];
assign dre_rw_writeChannel     =  tag_rw_hitBlockNum;
assign dre_rw_writeEnable      =  last_arb_write&&!arb_waitRequest;
assign dre_rw_writeRe          =  last_arb_byteEnable;                        /*这里的字节使能信号不是用来控制写入的，而是作为数据会被写入到RAM的*/

assign ctr_address             =  arb_address;                                /*这里直接赋值,不需要过寄存器缓冲*/
assign arb_isEnableCache       =  isCacheEn;
assign arb_readData            =  (ri_cmd==`cache_rw_cmd_iorw)?ri_rsp_data:{  /*如果是读IO指令,则arb_readData接受来自ri模块的反馈数据*/
                                    isWriteBuffHit&&readBuff_arb_byteEnable[3]?readBuff_arb_writeData[31:24]:data_rw_readData[31:24],/*如果写缓冲命中,则优先读写缓冲中的数据*/
                                    isWriteBuffHit&&readBuff_arb_byteEnable[2]?readBuff_arb_writeData[23:16]:data_rw_readData[23:16],
                                    isWriteBuffHit&&readBuff_arb_byteEnable[1]?readBuff_arb_writeData[15:8] :data_rw_readData[15:8] ,
                                    isWriteBuffHit&&readBuff_arb_byteEnable[0]?readBuff_arb_writeData[7:0]  :data_rw_readData[7:0]
                                  };
assign arb_readDataValid       =  (state==state_idle)?(last_arb_read&&!rw_waitRequest&&(last_state!=state_waitDone)):ri_cmd_ready&&last_arb_read;/*idle:要求上一次是读命令,并且没遇到都错误、上一次的状态不是waiDone状态*/

assign isCacheEn               =  ctr_isEnableCache;
assign isIoAddr                =  ctr_isIOAddrBlock;
assign isHit                   =  tag_rw_isHit;
assign isRe                    =  (readableMask&last_arb_byteEnable)==last_arb_byteEnable;
assign isR                     =  last_arb_read;
assign isW                     =  last_arb_write;
assign isWriteBuffHit          =  readBuff_arb_write&&(readBuff_arb_address==last_arb_address);
assign readableMask            =  isWriteBuffHit?(dre_rw_readRe|readBuff_arb_byteEnable):dre_rw_readRe;

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

always @(posedge clk)  begin
  last_isNeedSendCmdToRi<=isNeedSendCmdToRi;
  sel<=isNeedSendCmdToRi&&!ri_cmd_ready;
end

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
    if(!last_isNeedSendCmdToRi) begin
      /*缓存其它信号*/
      {last_isHit,last_hitBlockNum,last_isHaveFreeBlock,last_freeBlockNum}
        <={tag_rw_isHit,tag_rw_hitBlockNum,tag_rw_isHaveFreeBlock,tag_rw_freeBlockNum};
    end
  end
end

/**************************************************************************
状态机
**************************************************************************/
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
        if(rw_waitRequest) begin/*读写遇到了异常*/
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
  .TAG_WIDTH (TAG_WIDTH)
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
