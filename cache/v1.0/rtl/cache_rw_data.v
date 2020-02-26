module cache_rw_data #(
  parameter ADDR_WIDTH=8
)(
  clk,
  /*选择信号*/
  sel,
  /*读写模块*/
  rw_readAddress,
  rw_rwChannel,
  rw_readData,
  rw_writeAddress,
  rw_writeByteEnable,
  rw_writeEnable,
  rw_writeData,
  /*替换模块*/
  ri_readAddress,
  ri_rwChannel,
  ri_readData,
  ri_writeAddress,
  ri_writeByteEnable,
  ri_writeEnable,
  ri_writeData
);
input                       clk;
input                       sel;

input   [1:0]               rw_rwChannel;
input   [ADDR_WIDTH-1:0]    rw_readAddress;
output  [31:0]              rw_readData;
input   [ADDR_WIDTH-1:0]    rw_writeAddress;
input   [3:0]               rw_writeByteEnable;
input                       rw_writeEnable;
input   [31:0]              rw_writeData;

input   [1:0]               ri_rwChannel;
input   [ADDR_WIDTH-1:0]    ri_readAddress;
output  [31:0]              ri_readData;
input   [ADDR_WIDTH-1:0]    ri_writeAddress;
input   [3:0]               ri_writeByteEnable;
input                       ri_writeEnable;
input   [31:0]              ri_writeData;

wire    [ADDR_WIDTH-1:0]    readAddress;
wire    [1:0]               readCh;
wire    [31:0]              readData;
wire    [ADDR_WIDTH-1:0]    writeAddress;
wire    [1:0]               writeCh;
wire    [3:0]               writeByteEnabl;
wire                        writeEnable;
wire    [31:0]              writeData;

assign {
  readAddress,
  readCh,
  writeAddress,
  writeCh,
  writeByteEnabl,
  writeEnable,
  writeData
}=sel?
{
  ri_readAddress,
  ri_rwChannel,
  ri_writeAddress,
  ri_rwChannel,
  ri_writeByteEnable,
  ri_writeEnable,
  ri_writeData
}:
{
  rw_readAddress,
  rw_rwChannel,
  rw_writeAddress,
  rw_rwChannel,
  rw_writeByteEnable,
  rw_writeEnable,
  rw_writeData
};
assign rw_readData=readData;
assign ri_readData=readData;

cache_rw_data_ram #(
  .ADDR_WIDTH(ADDR_WIDTH)
)
cache_rw_data_ram_inst0(
  .clk(clk),
  .readAddress(readAddress),
  .readCh(readCh),
  .readData(readData),
  .writeAddress(writeAddress),
  .writeCh(writeCh),
  .writeData(writeData),
  .writeEnable(writeEnable),
  .writeByteEnable(writeByteEnabl)
);

endmodule

/*****************************************************************************************************************
module:cache_rw_data
描述:存放数据
*****************************************************************************************************************/
module cache_rw_data_ram #(
  parameter ADDR_WIDTH
)(
  clk,
  readAddress,
  readCh,
  readData,
  writeAddress,
  writeCh,
  writeData,
  writeEnable,
  writeByteEnable
);
input                   clk;
input [ADDR_WIDTH-1:0]  readAddress;
input [1:0]             readCh;
output[31:0]            readData;
input [ADDR_WIDTH-1:0]  writeAddress;
input [1:0]             writeCh;
input [31:0]            writeData;
input                   writeEnable;
input [3:0]             writeByteEnable;

wire [31:0]  rds[3:0];
wire [127:0] rd,wd;
wire [15:0]  wbe;
wire [3:0]   bem;

assign {rds[0],rds[1],rds[2],rds[3]}=rd;
assign readData=rds[readCh];
assign wd={4{writeData}};
assign bem=4'd1<<writeCh;
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
