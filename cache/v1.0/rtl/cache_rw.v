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
localparam DATA_RAM_BE_WIDTH=(128+7)/8;

localparam TAG_RAM_ADDR_WIDTH=log2(SIZE/(64*4));
localparam TAG_RAM_BE_WIDTH=(128+7)/8;

localparam RE_RAM_ADDR_WIDTH=log2(SIZE/32);



endmodule

/*****************************************************************************************************************
module:cache_rw_data
描述:存放数据
*****************************************************************************************************************/
module cache_rw_data #(
  parameter ADDR_WIDTH=9
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
  parameter ADDR_WIDTH=5,
            TAG_ADDR_WIDTH=9
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
  parameter ADDR_WIDTH=10
)(
  clk,
  readAddress,
  readWay,
  readRe,
  writeAddress,
  writeRe,
  writeEnable
);
input clk;
input[ADDR_WIDTH-1:0] readAddress;
input[1:0]            readWay;
output[3:0]           readRe;
input[ADDR_WIDTH-1:0] writeAddress;
input[15:0]           writeRe;
input                 writeEnable;

wire[15:0] rd;
wire[3:0] rds[3:0];
assign {rds[0],rds[1],rds[2],rds[3]}=rd;
assign readRe=rds[readWay];

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
