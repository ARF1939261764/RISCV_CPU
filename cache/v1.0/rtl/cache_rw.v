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
  address,
  isIOAddrBlock,
  isEnableCache,
  /**/
  isRequest,
  m0_cmd,
  m0_cmd_valid,
  m0_cmd_ready
);
input clk,rest;
/*s0从机接口*/
input     [31:0]   s0_address;
input     [3:0]    s0_byteEnable;
input              s0_read;
output    [31:0]   s0_readData;
input              s0_write;
input     [31:0]   s0_writeData;
output             s0_waitRequest;
output             s0_readDataValid;
/**/
output    [31:0]   address;
input              isIOAddrBlock;
input              isEnableCache;
input              isRequest;
output reg[3:0]    m0_cmd;
output reg         m0_cmd_valid;
input              m0_cmd_ready;

/********************************************************
function:计算数据位宽
********************************************************/
function integer log2;
	input integer num;
	begin
		log2=0;
		while(2**log2<num) begin
			log2=log2+1;
		end
	end
endfunction

/********************************************************
width
********************************************************/
localparam DATA_RAM_ADDR_WIDTH=log2(SIZE/(32/8*4));

localparam TAG_RAM_ADDR_WIDTH=log2(SIZE/(64*4));

localparam DRE_RAM_ADDR_WIDTH=log2(SIZE/32);

localparam TAG_ADDR_WIDTH=32-(DATA_RAM_ADDR_WIDTH+2);

wire[DATA_RAM_ADDR_WIDTH-1:0] data_rAddr;
wire[1:0]                     data_rWay;
wire[31:0]                    data_rData;
wire[DATA_RAM_ADDR_WIDTH-1:0] data_wAddr;
wire[1:0]                     data_wWay;
wire[31:0]                    data_wData;
wire                          data_wEn;
wire[3:0]                     data_wByteEn;

wire[TAG_RAM_ADDR_WIDTH-1:0]  tag_rAddr;
wire[1:0]                     tag_rWay;
wire[31:0]                    tag_rData;
wire[TAG_RAM_ADDR_WIDTH-1:0]  tag_wAddr;
wire[1:0]                     tag_wWay;
wire[31:0]                    tag_wData;
wire                          tag_wEn;
wire[31:0]                    addr_Buff;
wire                          addr_isHit;
wire[1:0]                     addr_hitBlockNum;
wire                          isHaveFreeBlock;
wire[1:0]                     freeBlockNum;

wire[DRE_RAM_ADDR_WIDTH-1:0]  dre_rAddr;
wire[1:0]                     dre_rWay;
wire[3:0]                     dre_rData;
wire[15:0]                    dre_rDataAll;
wire[DRE_RAM_ADDR_WIDTH-1:0]  dre_wAddr;
wire[31:0]                    dre_wData;
wire                          dre_wEn;

assign tag_rAddr=   data_rAddr[DATA_RAM_ADDR_WIDTH-1:4];
assign tag_rWay =   data_rWay; 
assign tag_wAddr=   data_wAddr[DATA_RAM_ADDR_WIDTH-1:4];
assign tag_wWay =   data_wWay;

reg [31:0] last_s0_address;
reg [3:0]  last_s0_byteEnable;
reg        last_s0_read;
reg        last_s0_write;
reg [31:0] last_s0_writeData;

wire isCacheEn,isIoAddr,isHit,isWBuffHit,isRe,isR,isW;
wire isReadErr,isWriteErr,isSendCmdToRI;

assign isCacheEn      = isEnableCache;
assign isIoAddr       = isIOAddrBlock;
assign isHit          = addr_isHit;
assign isWBuffHit     = 0/**/;
assign isRe           = (last_s0_byteEnable&dre_rData)==last_s0_byteEnable/**/;
assign isR            = last_s0_read;/**/
assign isW            = last_s0_write;/**/

assign isReadErr      =   (
                            isIoAddr    ||  /*是IO地址*/
                            !isHit      ||  /*没有命中*/
                            !isWBuffHit ||  /*写缓冲寄存器也没有命中*/
                            !isRe           /*不可读*/ 
                          )&&isR;           /*当是读指令时^*/
                 
assign isWriteErr     =   (
                            isIoAddr    ||  /*是IO地址*/
                            !isHit          /*没有命中*/
                          )&&isW;           /*当是写指令时*/

assign isSendCmdToRI  =   isReadErr||isWriteErr||isRequest;

always @(posedge clk or negedge rest) begin
  if(!rest) begin
    {last_s0_byteEnable,last_s0_read,last_s0_write}<=0;
  end
  else begin
    if((!s0_waitRequest)&&isCacheEn) begin
      {last_s0_byteEnable,last_s0_read,last_s0_write}<={s0_byteEnable,s0_read,s0_write};
    end
  end
end


/*******************************************************************************
状态机
*******************************************************************************/
localparam  state_idle=1'd0,
            state_waitDone=1'd1;
          
reg state;
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    state<=state_idle;
  end
  else begin
    case(state)
      state_idle:begin
          state<=isSendCmdToRI?state_waitDone:state_idle;
        end
      state_waitDone:begin
          state<=m0_cmd_ready?state_idle:state_waitDone;
        end
      default:begin
          state<=state_idle;
        end
    endcase
  end
end
  
always @(posedge clk) begin
  case(state)
    state_idle:begin
        if(isReadErr||isWriteErr) begin
          m0_cmd<=isIoAddr?`cache_rw_cmd_iorw:`cache_rw_cmd_rb;
        end
        else begin
          m0_cmd<=`cache_rw_handleCtrCmd;
        end
        m0_cmd_valid<=isSendCmdToRI;
      end
    state_waitDone:begin
        m0_cmd_valid<=m0_cmd_ready?1'b0:1'b1;
      end
    default:begin
        m0_cmd_valid<=1'b0;
      end
  endcase
end

/*数据RAM*/
cache_rw_data #(
  .ADDR_WIDTH(DATA_RAM_ADDR_WIDTH)
)
cache_rw_data_inst0(
  .clk(clk),
  .readAddress(data_rAddr),
  .readWay(data_rWay),
  .readData(data_rData),
  .writeAddress(data_wAddr),
  .writeWay(data_wWay),
  .writeData(data_wData),
  .writeEnable(data_wEn),
  .writeByteEnable(data_wByteEn)
);

/*地址标签RAM*/
cache_rw_tag #(
  .ADDR_WIDTH(TAG_RAM_ADDR_WIDTH),
  .TAG_ADDR_WIDTH(TAG_ADDR_WIDTH)
)cache_rw_tag_inst0(
  .clk(clk),
  .readAddress(tag_rAddr),
  .readWay(tag_rWay),
  .readTag(tag_rData),
  .writeAddress(tag_wAddr),
  .writeWay(tag_wWay),
  .writeTag(tag_wData),
  .writeEnable(tag_wEn),
  .address(addr_Buff),
  .isHit(addr_isHit),
  .hitBlockNum(addr_hitBlockNum),
  .isHaveFreeBlock(isHaveFreeBlock),
  .freeBlockNum(freeBlockNum)
);
/*可读信息RAM*/
cache_rw_dre #(
  .ADDR_WIDTH(DRE_RAM_ADDR_WIDTH)
)cache_rw_dre_inst0(
  .clk(clk),
  .readAddress(dre_rAddr),
  .readWay(dre_rWay),
  .readRe(dre_rData),
  .readReAll(dre_rDataAll),
  .writeAddress(dre_wAddr),
  .writeRe(dre_wData),
  .writeEnable(dre_wEn)
);




endmodule

/*****************************************************************************************************************
module:cache_rw_data
描述:存放数据
*****************************************************************************************************************/
module cache_rw_data #(
  parameter ADDR_WIDTH
)(
  clk,
  readAddress,
  readWay,
  readData,
  writeAddress,
  writeWay,
  writeData,
  writeEnable,
  writeByteEnable
);
input                   clk;
input [ADDR_WIDTH-1:0]  readAddress;
input [1:0]             readWay;
output[31:0]            readData;
input [ADDR_WIDTH-1:0]  writeAddress;
input [1:0]             writeWay;
input [31:0]            writeData;
input                   writeEnable;
input [3:0]             writeByteEnable;

wire [31:0]  rds[3:0];
wire [127:0] rd,wd;
wire [15:0]  wbe;
wire [3:0]   bem;

assign {rds[0],rds[1],rds[2],rds[3]}=rd;
assign readData=rds[readWay];
assign wd={4{writeData}};
assign bem=4'd1<<writeWay;
assign wbe={{4{bem[0]}},{4{bem[1]}},{4{bem[2]}},{4{bem[3]}}}&{4{writeByteEnable}};

dualPortRam #(
	.WIDTH(32*4),		                            /*数据位宽*/
	.DEPTH(2**ADDR_WIDTH)	                      /*深度*/
)
dualPortRam_inst0_dataRam(
	.clk(clk),
	.readAddress(readAddress),	                /*读地址*/
	.readData(rd),							                /*读出的数据*/
	.writeAddress(writeAddress),                /*写地址*/
	.writeData(wd),						                  /*需要写入的数据*/
	.writeEnable(writeEnable),	                /*写使能*/
	.writeByteEnable(wbe)		                    /*字节使能信号*/
);

endmodule

/*****************************************************************************************************************
module:cache_rw_tag
描述:存放cache块相关信息
*****************************************************************************************************************/
module cache_rw_tag #(
  parameter ADDR_WIDTH,
            TAG_ADDR_WIDTH
)(
  clk,
  readAddress,
  readWay,
  readTag,
  writeAddress,
  writeWay,
  writeTag,
  writeEnable,
  address,
  isHit,
  hitBlockNum,
  isHaveFreeBlock,
  freeBlockNum
);
input                   clk;
input [ADDR_WIDTH-1:0]  readAddress;
input [1:0]             readWay;
output[31:0]            readTag;
input [ADDR_WIDTH-1:0]  writeAddress;
input [1:0]             writeWay;
input [31:0]            writeTag;
input                   writeEnable;
input [TAG_ADDR_WIDTH-1:0] address;
output reg              isHit;
output[1:0]             hitBlockNum;
output                  isHaveFreeBlock;
output[1:0]             freeBlockNum;

wire [31:0]  rds[3:0];
wire [127:0] rd,wd;
wire [15:0]  wbe;
wire [3:0]   bem;

assign {rds[0],rds[1],rds[2],rds[3]}=rd;
assign readTag=rds[readWay];
assign wd={4{writeTag}};
assign bem=4'd1<<writeWay;
assign wbe={{4{bem[0]}},{4{bem[1]}},{4{bem[2]}},{4{bem[3]}}};

dualPortRam #(
	.WIDTH(32*4),		                            /*数据位宽*/
	.DEPTH(2**ADDR_WIDTH)	                      /*深度*/
)
dualPortRam_inst0_tagRam(
	.clk(clk),
	.readAddress(readAddress),	                /*读地址*/
	.readData(rd),							                /*读出的数据*/
	.writeAddress(writeAddress),                /*写地址*/
	.writeData(wd),						                  /*需要写入的数据*/
	.writeEnable(writeEnable),	                /*写使能*/
	.writeByteEnable(wbe)		                    /*字节使能信号*/
);

reg[TAG_ADDR_WIDTH-1:0] addressBuff;
reg[3:0] addrEqual;

/*缓冲地址*/
always @(posedge clk) begin
  addressBuff<=address;
end

/*比较地址,判断是否命中*/
always @(*) begin:judgeHitBlock
  integer i;
  for(i=0;i<4;i=i+1) begin
    addrEqual[i]=(addressBuff==rds[i][TAG_ADDR_WIDTH-1:0]);
  end
  isHit=1'd0;
  for(i=0;i<4;i=i+1) begin
    isHit=isHit|addrEqual[i];
  end
end

/*判断是那一路命中*/
assign hitBlockNum={2{addrEqual[0]}}&2'd0
                  |{2{addrEqual[1]}}&2'd1
                  |{2{addrEqual[2]}}&2'd2
                  |{2{addrEqual[3]}}&2'd3;
                  
/*判断是否还有多余的块*/
assign isHaveFreeBlock=!(rds[0][TAG_ADDR_WIDTH]
                        &rds[1][TAG_ADDR_WIDTH]
                        &rds[2][TAG_ADDR_WIDTH]
                        &rds[3][TAG_ADDR_WIDTH]);

/*第几块是空闲的*/
assign freeBlockNum=rds[0][TAG_ADDR_WIDTH]?2'd0:
                    rds[1][TAG_ADDR_WIDTH]?2'd1:
                    rds[2][TAG_ADDR_WIDTH]?2'd2:
                    rds[3][TAG_ADDR_WIDTH]?2'd3:2'd0;
endmodule

/*****************************************************************************************************************
module:cache_rw_dre
描述:存放每个字节是否可读的信息
*****************************************************************************************************************/
module cache_rw_dre #(
  parameter ADDR_WIDTH
)(
  clk,
  readAddress,
  readWay,
  readRe,
  readReAll,
  writeAddress,
  writeRe,
  writeEnable
);
input clk;
input[ADDR_WIDTH-1:0] readAddress;
input[1:0]            readWay;
output[3:0]           readRe;
output[15:0]          readReAll;
input[ADDR_WIDTH-1:0] writeAddress;
input[15:0]           writeRe;
input                 writeEnable;

wire[15:0] rd;
wire[3:0] rds[3:0];
assign {rds[0],rds[1],rds[2],rds[3]}=rd;
assign readRe=rds[readWay];
assign readReAll=rd;

dualPortRam #(
	.WIDTH(16),		                            /*数据位宽*/
	.DEPTH(2**ADDR_WIDTH)	                      /*深度*/
)
dualPortRam_inst0_tagRam(
	.clk(clk),
	.readAddress(readAddress),	                /*读地址*/
	.readData(rd),							                /*读出的数据*/
	.writeAddress(writeAddress),                /*写地址*/
	.writeData(writeRe),						            /*需要写入的数据*/
	.writeEnable(writeEnable),	                /*写使能*/
	.writeByteEnable(2'b11)		                  /*字节使能信号*/
);

endmodule
