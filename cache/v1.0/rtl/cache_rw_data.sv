/*****************************************************************************************************************
module:cache_rw_data
描述:存放数据,提供两组接口,当sel信号为0时,cache_rw_data模块由rw端口控制,当sel信号为1时:cache_rw_data模块由ri端口控制
*****************************************************************************************************************/
module cache_rw_data #(
  parameter ADDR_WIDTH=9
)(
  /*时钟*/
  input                       clk,
  /*sel*/
  input                       sel,
  /*接到rw模块*/
  input   [ADDR_WIDTH-1:0]    rw_readAddress,
  input   [1:0]               rw_rwChannel,
  output  [31:0]              rw_readData,
  input   [ADDR_WIDTH-1:0]    rw_writeAddress,
  input   [3:0]               rw_writeByteEnable,
  input                       rw_writeEnable,
  input   [31:0]              rw_writeData,
  /*接到ri模块*/
  input   [1:0]               ri_rwChannel,
  input   [ADDR_WIDTH-1:0]    ri_readAddress,
  output  [31:0]              ri_readData,
  input   [ADDR_WIDTH-1:0]    ri_writeAddress,
  input   [3:0]               ri_writeByteEnable,
  input                       ri_writeEnable,
  input   [31:0]              ri_writeData
);
/*****************************************************************************************************************
wire and reg
*****************************************************************************************************************/
wire    [ADDR_WIDTH-1:0]    readAddress;
wire    [1:0]               readChannel;
wire    [31:0]              readData;
wire    [ADDR_WIDTH-1:0]    writeAddress;
wire    [1:0]               writeChannel;
wire    [3:0]               writeByteEnable;
wire                        writeEnable;
wire    [31:0]              writeData;

/*****************************************************************************************************************
连线
*****************************************************************************************************************/
/*mux*/
assign {
  readAddress,
  readChannel,
  writeAddress,
  writeChannel,
  writeByteEnable,
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
/*输出数据*/
assign rw_readData=readData;
assign ri_readData=readData;

/*****************************************************************************************************************
实例化module
*****************************************************************************************************************/
cache_rw_data_ram #(
  .ADDR_WIDTH(ADDR_WIDTH)
)
cache_rw_data_ram_inst0(
  .clk              (clk            ),
  .readAddress      (readAddress    ),
  .readChannel      (readChannel    ),
  .readData         (readData       ),
  .writeAddress     (writeAddress   ),
  .writeChannel     (writeChannel   ),
  .writeData        (writeData      ),
  .writeEnable      (writeEnable    ),
  .writeByteEnable  (writeByteEnable)
);

endmodule

/*****************************************************************************************************************
module:cache_rw_data
描述:存放数据
*****************************************************************************************************************/
module cache_rw_data_ram #(
  parameter ADDR_WIDTH=9
)(
  input                   clk,
  input [ADDR_WIDTH-1:0]  readAddress,
  input [1:0]             readChannel,
  output[31:0]            readData,
  input [ADDR_WIDTH-1:0]  writeAddress,
  input [1:0]             writeChannel,
  input [31:0]            writeData,
  input                   writeEnable,
  input [3:0]             writeByteEnable
);

wire [31:0]             rds[3:0];
wire [127:0]            rd,wd;
wire [15:0]             wbe;
wire [3:0]              bem;

assign {rds[3],rds[2],rds[1],rds[0]}  =  rd;
assign readData                       =  rds[readChannel];
assign wd                             =  {4{writeData}};
assign bem                            =  4'd1<<writeChannel;
assign wbe                            =  {{4{bem[3]}},{4{bem[2]}},{4{bem[1]}},{4{bem[0]}}}&{4{writeByteEnable}};

dualPortRam #(
	.WIDTH(128),		                            /*数据位宽*/
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
