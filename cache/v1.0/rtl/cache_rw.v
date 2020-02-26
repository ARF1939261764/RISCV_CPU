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

localparam TAG_RAM_ADDR_WIDTH=DATA_RAM_ADDR_WIDTH-4;

localparam DRE_RAM_ADDR_WIDTH=log2(SIZE/32)+1;

localparam TAG_ADDR_WIDTH=32-(DATA_RAM_ADDR_WIDTH+2);

wire[DATA_RAM_ADDR_WIDTH-1:0] data_rAddr;
wire[1:0]                     data_rCh;
wire[31:0]                    data_rData;
wire[DATA_RAM_ADDR_WIDTH-1:0] data_wAddr;
wire[1:0]                     data_wCh;
wire[31:0]                    data_wData;
wire                          data_wEn;
wire[3:0]                     data_wByteEn;

wire[TAG_RAM_ADDR_WIDTH-1:0]  tag_rAddr;
wire[1:0]                     tag_rCh;
wire[31:0]                    tag_rData;
wire[TAG_RAM_ADDR_WIDTH-1:0]  tag_wAddr;
wire[1:0]                     tag_wCh;
wire[31:0]                    tag_wData;
wire                          tag_wEn;
wire[31:0]                    addr_Buff;
wire                          addr_isHit;
wire[1:0]                     addr_hitBlockNum;
wire                          isHaveFreeBlock;
wire[1:0]                     freeBlockNum;

wire[DRE_RAM_ADDR_WIDTH-1:0]  dre_rAddr;
wire[1:0]                     dre_rCh;
wire[3:0]                     dre_rData;
wire[7:0]                     dre_rDataAll;
wire[DRE_RAM_ADDR_WIDTH-1:0]  dre_wAddr;
wire[1:0]                     dre_wCh;
wire[31:0]                    dre_wData;
wire                          dre_wEn;

wire isCacheEn,isIoAddr,isHit,isWBuffHit,isRe,isR,isW;
wire isReadErr,isWriteErr,isSendCmdToRI;

reg [31:0]                    last_s0_address;
reg [3:0]                     last_s0_byteEnable;
reg                           last_s0_read;
reg                           last_s0_write;
reg [31:0]                    last_s0_writeData;

assign tag_rAddr  =           data_rAddr[DATA_RAM_ADDR_WIDTH-1:4];
assign tag_rCh    =           data_rCh; 
assign tag_wAddr  =           data_wAddr[DATA_RAM_ADDR_WIDTH-1:4];
assign tag_wCh    =           data_wCh;
assign dre_rAddr  =           data_rAddr;
assign dre_rCh    =           data_rCh;
assign dre_wAddr  =           data_wAddr;
assign dre_wCh    =           data_wCh;

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
  .readCh(data_rCh),
  .readData(data_rData),
  .writeAddress(data_wAddr),
  .writeCh(data_wCh),
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
  .readCh(tag_rCh),
  .readTag(tag_rData),
  .writeAddress(tag_wAddr),
  .writeCh(tag_wCh),
  .writeTag(tag_wData),
  .writeEnable(tag_wEn),
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
  .readCh(dre_rCh),
  .readRe(dre_rData),
  .readReAll(dre_rDataAll),
  .writeAddress(dre_wAddr),
  .writeCh(dre_wCh),
  .writeRe(dre_wData),
  .writeEnable(dre_wEn)
);

endmodule






