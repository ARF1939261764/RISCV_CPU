`include "cache_define.sv"

module cache_ctr #(
  parameter ADDR_BLOCK_NUM=4
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
  /*其它*/
  address,
  isIOAddrBlock,
  isEnableCache,
  cmd,
  cmd_ready
);
/*时钟、复位*/
input                 clk,rest;
/*s0从机接口*/
input         [31:0]  s0_address;
input         [3:0]   s0_byteEnable;
input                 s0_read;
output reg    [31:0]  s0_readData;
input                 s0_write;
input         [31:0]  s0_writeData;
output                s0_waitRequest;
output reg            s0_readDataValid;
/*其它*/
input         [31:0]  address;
output reg            isIOAddrBlock;
output                isEnableCache;
output reg    [2:0]   cmd;
input                 cmd_ready;

/********************************************************
地址宽度
********************************************************/
localparam    ADDR_WIDTH=$clog2(ADDR_BLOCK_NUM*2*4+4);/*每个地址块用2个边界确定，每个边界用4个字节描述,另外再加一个控制寄存器*/

/********************************************************
地址块寄存器
********************************************************/
reg[31:10]     regArray[ADDR_BLOCK_NUM*2:0];

/********************************************************
判断是否在IO地址中
********************************************************/
always @(*) begin:judgeBlock
  integer i;
  isIOAddrBlock=1'b0;
  for(i=1;i<=ADDR_BLOCK_NUM;i=i+1) begin
    isIOAddrBlock=isIOAddrBlock||((regArray[i*2-1]<=address[31:10])&&(address[31:10]<=regArray[i*2]));
  end
  isIOAddrBlock=isIOAddrBlock||address[31];
end

/********************************************************
读写寄存器
********************************************************/
reg last_en;
always @(posedge clk or negedge rest) begin
  if(!rest) begin:restBlock
    integer i;
    for(i=1;i<=2*ADDR_BLOCK_NUM;i=i+1) begin
      regArray[i]<=22'd1<<21;
    end
    regArray[0]<=22'd1<<6;/*使能位默认为1*/
    last_en<=1'd1;
    s0_readData<=32'd0;
  end
  else begin
    last_en<=regArray[0][16];
    if(s0_write) begin
      regArray[s0_address/4]<=s0_writeData[31:10];
    end
    if(s0_read) begin
      s0_readData<={regArray[s0_address/4],10'd0};
    end
  end
end

/********************************************************
flag
********************************************************/
wire writeCtrReg;
wire startRush;
wire startClear;
assign writeCtrReg=(s0_address[31:2]==30'd0)&&s0_write;
assign startRush=s0_writeData[17]&&writeCtrReg;
assign startClear=(last_en&&(~s0_writeData[16]))&&writeCtrReg;

/********************************************************
指令控制
********************************************************/
localparam  cmd_idle=2'd0,
            cmd_waitDone=2'd1,
            cmd_init=2'd2;
reg[1:0]    cmd_state;
/*状态机第一部分*/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    cmd_state<=cmd_init;
  end
  else begin
    case(cmd_state)
      cmd_init:begin
            cmd_state<=cmd_waitDone;
          end
      cmd_idle:begin
          cmd_state<=({startRush,startClear}==2'd0)?cmd_idle:cmd_waitDone;
        end
      cmd_waitDone:begin
          cmd_state<=cmd_ready?cmd_idle:cmd_waitDone;
        end
      default:begin
          cmd_state<=cmd_idle;
        end
    endcase
  end
end
/*状态机第二部分*/
always @(posedge clk) begin
  if(!rest) begin
    cmd<=`cache_ctr_cmd_init;
  end
  else begin
    case(cmd_state)
      cmd_init:begin
            cmd<=`cache_ctr_cmd_init;
          end
      cmd_idle:begin
          case({startRush,startClear})
            2'b01,2'b11:begin
                cmd<=`cache_ctr_cmd_clear;
              end
            2'd2:begin
                cmd<=`cache_ctr_cmd_wb;
              end
            default:begin
                cmd<=`cache_ctr_cmd_nop;
              end
          endcase
        end
      cmd_waitDone:begin
          cmd<=cmd_ready?`cache_ctr_cmd_nop:cmd;
        end
      default:begin
          cmd<=1'd0;
        end
    endcase
  end
end

/********************************************************
控制控制信号
********************************************************/
always @(posedge clk) begin
  s0_readDataValid<=s0_read;
end
assign s0_waitRequest=1'b1;
assign isEnableCache=regArray[0][16];

endmodule
