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

/*************************************************************************
状态机
*************************************************************************/
parameter state_idle            = 4'd0,
          state_waitReadIODone  = 4'd1,
          state_waitWriteIODone = 4'd2,
          state_readMiss        = 4'd3,
          state_writeMiss       = 4'd4,
          

parameter

endmodule // cache_ri