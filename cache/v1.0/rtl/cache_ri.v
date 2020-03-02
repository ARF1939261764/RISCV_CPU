`include "cache_define.v"

module cache_ri #(
  parameter SIZE = 8*1024
)(
  clk,
  rest,
  /*接到仲裁器*/
  arb_address,        
  arb_byteEnable,     
  arb_read,
  arb_write,          
  arb_writeData,      
  arb_waitRequest,
  arb_beginBurstTransfer,
  arb_burstCount,
  arb_readData,   
  arb_readDataValid,

  ctr_cmd,
  ctr_cmd_valid,
  ctr_cmd_ready,
  ctr_isEnableCache,

  rw_cmd,
  rw_cmd_valid,
  rw_cmd_ready,
  rw_isRequest,
  rw_rsp_data,
  rw_last_arb_address,
  rw_last_arb_writeData,
  rw_last_arb_byteEnable,
  rw_last_arb_read,
  rw_last_arb_write,
  rw_isHit,
  rw_hitBlockNum,
  rw_isHaveFreeBlock,
  rw_freeBlockNum,
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
  /**/
  dre_ri_readAddress,
  dre_ri_readChannel,
  dre_ri_readData,
  dre_ri_writeAddress,
  dre_ri_writeChannel,
  dre_ri_writeEnable,
  dre_ri_writeData
);

input                                    clk;
input                                    rest;

output   [31:0]                          arb_address;
output   [3:0]                           arb_byteEnable;
output                                   arb_read;
output                                   arb_write;
output   [31:0]                          arb_writeData;
input                                    arb_waitRequest;
output                                   arb_beginBurstTransfer;
output   [7:0]                           arb_burstCount;
input    [31:0]                          arb_readData;
input                                    arb_readDataValid;

input    [2:0]                           ctr_cmd;
input                                    ctr_cmd_valid;
output                                   ctr_cmd_ready;
input                                    ctr_isEnableCache;

input    [3:0]                           rw_cmd;
input                                    rw_cmd_valid;
output                                   rw_cmd_ready;
output                                   rw_isRequest;
output   [31:0]                          rw_rsp_data;
input    [31:0]                          rw_last_arb_address;
input    [31:0]                          rw_last_arb_writeData;
input    [3:0]                           rw_last_arb_byteEnable;
input                                    rw_last_arb_read;
input                                    rw_last_arb_write;
input                                    rw_isHit;
input    [1:0]                           rw_hitBlockNum;
input                                    rw_isHaveFreeBlock;
input    [1:0]                           rw_freeBlockNum;
/**/
output  [DATA_RAM_ADDR_WIDTH-1:0]        data_ri_readAddress;
output  [1:0]                            data_ri_rwChannel;
input   [31:0]                           data_ri_readData;
output  [DATA_RAM_ADDR_WIDTH-1:0]        data_ri_writeAddress;
output  [3:0]                            data_ri_writeByteEnable;
output                                   data_ri_writeEnable;
output  [31:0]                           data_ri_writeData;
/**/
output  [TAG_RAM_ADDR_WIDTH-1:0]         tag_ri_readAddress;
output  [1:0]                            tag_ri_readChannel;
input   [31:0]                           tag_ri_readData;
output  [TAG_RAM_ADDR_WIDTH-1:0]         tag_ri_writeAddress;
output  [1:0]                            tag_ri_writeChannel;
output                                   tag_ri_writeEnable;
output  [31:0]                           tag_ri_writeData;
/**/
output  [DRE_RAM_ADDR_WIDTH-0:0]         dre_ri_readAddress;
output                                   dre_ri_readChannel;
input   [7:0]                            dre_ri_readData;
output  [DRE_RAM_ADDR_WIDTH-1:0]         dre_ri_writeAddress;
output  [1:0]                            dre_ri_writeChannel;
output                                   dre_ri_writeEnable;
output  [7:0]                            dre_ri_writeData;

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
localparam DATA_RAM_ADDR_WIDTH  = `SIZE_TO_DATA_RAM_ADDR_WIDTH;
localparam TAG_RAM_ADDR_WIDTH   = `SIZE_TO_TAG_RAM_ADDR_WIDTH;
localparam DRE_RAM_ADDR_WIDTH   = `SIZE_TO_DRE_RAM_ADDR_WIDTH;
localparam TAG_ADDR_WIDTH       = `SIZE_TO_TAG_ADDR_WIDTH;

/**************************************************************************
wire and reg
**************************************************************************/
wire                  isDirtyBlock;
reg  [1:0]            replaceFIFO[2**TAG_RAM_ADDR_WIDTH-1:0];
reg  [3:0]            rwChannel;
reg  [31:0]           readAddress;
reg  [31:0]           writeAddress;

/**************************************************************************
连线
**************************************************************************/
assign isDirtyBlock                 =     tag_ri_readData[TAG_ADDR_WIDTH+1];
assign data_ri_readAddress          =     readAddress[DATA_RAM_ADDR_WIDTH+1:2];
assign data_ri_writeAddress         =     writeAddress[DATA_RAM_ADDR_WIDTH+1:2];
assign data_ri_rwChannel            =     rwChannel;

assign tag_ri_readAddress           =     readAddress[DATA_RAM_ADDR_WIDTH+1:6];
assign tag_ri_writeAddress          =     writeAddress[DATA_RAM_ADDR_WIDTH+1:6];
assign tag_ri_readChannel           =     rwChannel;
assign tag_ri_writeChannel          =     rwChannel;

assign dre_ri_readAddress           =     readAddress[DATA_RAM_ADDR_WIDTH+2:2];
assign dre_ri_writeAddress          =     writeAddress[DATA_RAM_ADDR_WIDTH+2:3];
assign dre_ri_readChannel           =     rwChannel;
assign dre_ri_writeChannel          =     rwChannel;

assign rw_rsp_data                  =     arb_readData;
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

wire endFlag_state_waitReadIODone   =     (!arb_read||!arb_waitRequest)&&arb_readDataValid;
wire endFlag_state_waitWriteIODone  =     (!arb_write||!arb_waitRequest);
/*第一段*/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    state<=state_idle;
  end
  else begin
    case(state)
      state_idle:begin
          case(rw_cmd)
            `cache_rw_cmd_rb:state<=rw_last_arb_read?state_readMiss:state_writeMiss;
            `cache_rw_cmd_iorw:state<=rw_last_arb_read?state_waitReadIODone:state_waitWriteIODone;
            `cache_rw_handleCtrCmd:state<=state_handleCtrCmd;
            default:state<=state_idle;
          endcase
        end
      state_waitReadIODone:begin
          state<endFlag_state_waitReadIODone?state_idle:state_waitReadIODone;
        end
      state_waitWriteIODone:begin
          state<=endFlag_state_waitWriteIODone?state_idle:state_waitWriteIODone;
        end
      state_readMiss:begin
          if(rw_isHit) begin
            state<=state_readIn;
          end
          else
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
    data_ri_writeByteEnable<=1'd0;
    tag_ri_writeEnable<=1'd0;
    dre_ri_writeEnable<=1'd0;
  end
  else begin
    case(state)
      state_idle:begin
          case(rw_cmd)
            `cache_rw_cmd_rb:begin
                readAddress<=rw_last_arb_address;
                rwChannel<=rw_isHaveFreeBlock?rw_freeBlockNum:replaceFIFO[DATA_RAM_ADDR_WIDTH+1:6];
                arb_read<=1'd0;
                arb_write<=1'd0;
              end
            `cache_rw_cmd_iorw:begin
                arb_address<=rw_last_arb_address;
                arb_writeData<=rw_last_arb_writeData;
                arb_read<=rw_last_arb_read;
                arb_write<=rw_last_arb_write;
                arb_byteEnable<=rw_last_arb_byteEnable;
              end
            default:begin
                arb_read<=1'd0;
                arb_write<=1'd0;
              end
          endcase
          data_ri_writeByteEnable<=1'd0;
          tag_ri_writeEnable<=1'd0;
          dre_ri_writeEnable<=1'd0;
        end
      state_waitReadIODone:begin
          arb_read<=!arb_waitRequest?1'd0:arb_read;
        end
      state_waitWriteIODone:begin
          arb_write<=!arb_waitRequest?1'd0:arb_write;
        end
      state_readMiss,state_writeMiss:begin
          readAddress<={rw_last_arb_address[31:6],6'd0};
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

always @(*) begin
  case (state)
    state_idle:begin
        rw_cmd_ready=1'd0;
      end
    state_waitReadIODone:begin
        rw_cmd_ready=endFlag_state_waitReadIODone;
      end
    state_waitWriteIODone:begin
        rw_cmd_ready=endFlag_state_waitWriteIODone;
      end
    default:begin
        rw_cmd_ready=1'd0;
      end
    default: 
  endcase
end

endmodule
