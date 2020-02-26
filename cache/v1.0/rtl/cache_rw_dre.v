module cache_rw_dre #(
  parameter ADDR_WIDTH=8
)(
  clk,
  sel,
  rw_readAddress,
  rw_readChannel,
  rw_readByteEnable,
  rw_isReadable,
  rw_writeAddress,
  rw_writeChannel,
  rw_writeEnable,

  ri_readAddress,
  ri_readChannel,
  ri_readData,
  ri_writeAddress,
  ri_writeChannel,
  ri_writeEnable,
  ri_writeData,
  ri_isReadable
);
input                   clk;
input                   sel;
input  [ADDR_WIDTH-1:0] rw_readAddress;
input  [1:0]            rw_readChannel;
input  [3:0]            rw_readByteEnable;
output                  rw_isReadable;
input  [ADDR_WIDTH-1:0] rw_writeAddress;
input  [1:0]            rw_writeChannel;
input                   rw_writeEnable;
input  [ADDR_WIDTH-1:0] ri_readAddress;
input                   ri_readChannel;
input  [7:0]            ri_readData;
input  [ADDR_WIDTH-1:0] ri_writeAddress;
input  [1:0]            ri_writeChannel;
input                   ri_writeEnable;
input  [7:0]            ri_writeData;
output                  ri_isReadable;

wire [ADDR_WIDTH-1:0]   readAddress;
wire [1:0]              readCh;
wire [3:0]              readRe;
wire [7:0]              readReAll;
wire [ADDR_WIDTH-1:0]   writeAddress;
wire [1:0]              writeCh;
wire [7:0]              writeRe;
wire                    writeEnable;



cache_rw_dre_ram #(
  .ADDR_WIDTH(ADDR_WIDTH)
)cache_rw_dre_ram_inst0(
  .clk(clk),
  .readAddress(readAddress),
  .readCh(readCh),
  .readRe(readRe),
  .readReAll(readReAll),
  .writeAddress(writeAddress),
  .writeCh(writeCh),
  .writeRe(writeRe),
  .writeEnable(writeEnable)
);

endmodule

/*****************************************************************************************************************
module:cache_rw_dre_ram
描述:存放每个字节是否可读的信息
*****************************************************************************************************************/
module cache_rw_dre_ram #(
  parameter ADDR_WIDTH
)(
  clk,
  readAddress,
  readCh,
  readRe,
  readReAll,
  writeAddress,
  writeCh,
  writeRe,
  writeEnable
);
input clk;
input [ADDR_WIDTH-1:0]  readAddress;
input [1:0]             readCh;
output[3:0]             readRe;
output[7:0]             readReAll;
input [ADDR_WIDTH-1:0]  writeAddress;
input [1:0]             writeCh;
input [7:0]             writeRe;
input                   writeEnable;

wire[31:0] rd,wd;
wire[7:0] rds[3:0];

assign {rds[0],rds[1],rds[2],rds[3]}=rd;

assign readRe=readAddress[0]?readReAll[7:4]:readReAll[3:0];
assign readReAll=rds[readCh];

assign wd={4{writeRe}};

dualPortRam #(
	.WIDTH(32),		                                  /*数据位宽*/
	.DEPTH(2**ADDR_WIDTH)	                          /*深度*/
)
dualPortRam_inst0_tagRam(
	.clk(clk),
	.readAddress(readAddress[ADDR_WIDTH-1:1]),	    /*读地址*/
	.readData(rd),							                    /*读出的数据*/
	.writeAddress(writeAddress[ADDR_WIDTH-1:1]),    /*写地址*/
	.writeData(wd),						                      /*需要写入的数据*/
	.writeEnable(writeEnable),	                    /*写使能*/
	.writeByteEnable(4'd8>>writeCh)		            /*字节使能信号*/
);

endmodule
