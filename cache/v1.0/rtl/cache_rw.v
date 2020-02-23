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
  isEnableCache
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
input              s0_readDataValid;
/**/
output    [31:0]   address;
input              isIOAddrBlock;
input              isEnableCache;

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
localparam DATA_RAM_BE_WIDTH=(DATA_RAM_ADDR_WIDTH+7)/8;

localparam TAG_RAM_ADDR_WIDTH=log2(SIZE/(64*4));
localparam TAG_RAM_BE_WIDTH=(TAG_RAM_ADDR_WIDTH+7)/8;

localparam RE_RAM_ADDR_WIDTH=log2(SIZE/32);
localparam RE_RAM_BE_WIDTH=(RE_RAM_ADDR_WIDTH+7)/8;

wire[DATA_RAM_ADDR_WIDTH-1:0]     dataRam_readAddress;
wire[127:0]                       dataRam_readData;
wire[DATA_RAM_ADDR_WIDTH-1:0]     dataRam_writeAddress;
wire[127:0]                       dataRam_writeData;
wire                              dataRam_writeEnable;
wire[DATA_RAM_BE_WIDTH-1:0]       dataRam_writeByteEnable;

wire[TAG_RAM_ADDR_WIDTH-1:0]      tagRam_readAddress;
wire[127:0]                       tagRam_readData;
wire[TAG_RAM_ADDR_WIDTH-1:0]      tagRam_writeAddress;
wire[127:0]                       tagRam_writeData;
wire                              tagRam_writeEnable;
wire[TAG_RAM_BE_WIDTH-1:0]        tagRam_writeByteEnable;

wire[RE_RAM_ADDR_WIDTH-1:0]       reRam_readAddress;
wire[127:0]                       reRam_readData;
wire[RE_RAM_ADDR_WIDTH-1:0]       reRam_writeAddress;
wire[127:0]                       reRam_writeData;
wire                              reRam_writeEnable;
wire[RE_RAM_BE_WIDTH-1:0]         reRam_writeByteEnable;

dualPortRam #(
	.WIDTH(32*4),		                            /*数据位宽*/
	.DEPTH(SIZE/(32/8*4))	                      /*深度*/
)
dualPortRam_inst0_dataRam(
	.clk(clk),
	.readAddress(dataRam_readAddress),					/*读地址*/
	.readData(dataRam_readData),							  /*读出的数据*/
	.writeAddress(dataRam_writeAddress),				/*写地址*/
	.writeData(dataRam_writeData),						  /*需要写入的数据*/
	.writeEnable(dataRam_writeEnable),					/*写使能*/
	.writeByteEnable(dataRam_writeByteEnable)		/*字节使能信号*/
);


dualPortRam #(
	.WIDTH(32*4),		                            /*数据位宽*/
	.DEPTH(SIZE/(64*4))                         /*深度*/
)
dualPortRam_inst0_tagRam(
	.clk(clk),
	.readAddress(tagRam_readAddress),					  /*读地址*/
	.readData(tagRam_readData),							    /*读出的数据*/
	.writeAddress(tagRam_writeAddress),					/*写地址*/
	.writeData(tagRam_writeData),						    /*需要写入的数据*/
	.writeEnable(tagRam_writeEnable),					  /*写使能*/
	.writeByteEnable(tagRam_writeByteEnable)		/*字节使能信号*/
);

dualPortRam #(
	.WIDTH(32),		                              /*数据位宽*/
	.DEPTH(SIZE/32)	                            /*深度*/
)
dualPortRam_inst0_reRam(
	.clk(clk),
	.readAddress(reRam_readAddress),					  /*读地址*/
	.readData(reRam_readData),							    /*读出的数据*/
	.writeAddress(reRam_writeAddress),					/*写地址*/
	.writeData(reRam_writeData),						    /*需要写入的数据*/
	.writeEnable(reRam_writeEnable),					  /*写使能*/
	.writeByteEnable(reRam_writeByteEnable)			/*字节使能信号*/
);


endmodule


module cache_rw_data #(
  parameter ADDR_WIDTH=10
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
input          clk;
input [31:0]   readAddress;
input [1:0]    readWay;
output[31:0]   readData;
input [31:0]   writeAddress;
input [1:0]    writeWay;
input [31:0]   writeData;
input          writeEnable;
input [3:0]    writeByteEnable;

wire[127:0] rd,wd;
wire[15:0] wbe;
wire[31:0] rds[3:0];
wire[3:0] bem;

assign {rds[0],rds[1],rds[2],rds[3]}=rd;
assign readData=rds[readWay];

assign wd={4{writeData}};

assign bem=4'd1<<writeWay;

assign wbe={{4{bem[0]}},{4{bem[1]}},{4{bem[2]}},{4{bem[3]}}}&{4{writeByteEnable}};

dualPortRam #(
	.WIDTH(32*4),		                            /*数据位宽*/
	.DEPTH(2**ADDR_WIDTH/4)	                    /*深度*/
)
dualPortRam_inst0_dataRam(
	.clk(clk),
	.readAddress(readAddress[ADDR_WIDTH-1:2]),	/*读地址*/
	.readData(rd),							                /*读出的数据*/
	.writeAddress(writeAddress[ADDR_WIDTH-1:2]),/*写地址*/
	.writeData(wd),						                  /*需要写入的数据*/
	.writeEnable(writeEnable),	                /*写使能*/
	.writeByteEnable(wbe)		                    /*字节使能信号*/
);

/*检查*/
always @(posedge clk) begin
  if(readAddress[1:0]!=0) begin
    $display("cache unaligned access:%d\n",$time);
  end
end

endmodule

module cache_rw_tag #(
  parameter ADDR_WIDTH=10
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
)
input          clk;
input [31:0]   readAddress;
input [1:0]    readWay;
output[31:0]   readData;
input [31:0]   writeAddress;
input [1:0]    writeWay;
input [31:0]   writeData;
input          writeEnable;
input [3:0]    writeByteEnable;



endmodule
