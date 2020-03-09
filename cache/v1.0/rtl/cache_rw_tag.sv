/****************************************************************************
存放cache块的标签、是否占用、是否为脏块
TAG_WIDTH(标签宽度)计算公式:TAG_WIDTH=32-log2(SIZE/4);其中的4指4路组相联
****************************************************************************/
module cache_rw_tag #(
  parameter ADDR_WIDTH=9,
            TAG_WIDTH=21
)(
  input                         clk,
  input                         sel,
  input [ADDR_WIDTH-1:0]        rw_readAddress,
  input [ADDR_WIDTH-1:0]        rw_writeAddress,
  input                         rw_writeEnable,
  input [TAG_WIDTH-1:0]         rw_tag,
  output                        rw_isHit,
  output[1:0]                   rw_hitBlockNum,
  output                        rw_isHaveFreeBlock,
  output[1:0]                   rw_freeBlockNum,

  input [ADDR_WIDTH-1:0]        ri_readAddress,
  input [1:0]                   ri_readChannel,
  output[31:0]                  ri_readData,
  input [ADDR_WIDTH-1:0]        ri_writeAddress,
  input [1:0]                   ri_writeChannel,
  input                         ri_writeEnable,
  input [31:0]                  ri_writeData
);
/*****************************************************************************************************************
wire and reg
*****************************************************************************************************************/
wire [ADDR_WIDTH-1:0]         readAddress;
wire [1:0]                    readChannel;
wire [31:0]                   readTag;
wire [31:0]                   readHitTag;
wire [ADDR_WIDTH-1:0]         writeAddress;
wire [1:0]                    writeChannel;
wire [31:0]                   writeTag;
wire                          writeEnable;
wire                          isHit;
wire [1:0]                    hitBlockNum;
wire                          isHaveFreeBlock;
wire [1:0]                    freeBlockNum;

/*****************************************************************************************************************
连线
*****************************************************************************************************************/
assign readAddress        =   sel?ri_readAddress:rw_readAddress;
assign readChannel        =   ri_readChannel;
assign writeAddress       =   sel?ri_writeAddress:rw_writeAddress;
assign writeChannel       =   sel?ri_writeChannel:hitBlockNum;
assign writeTag           =   sel?ri_writeData:(readHitTag|(1<<TAG_WIDTH+1));
assign writeEnable        =   sel?ri_writeEnable:rw_writeEnable;
        
assign rw_isHit           =   isHit;
assign rw_hitBlockNum     =   hitBlockNum;
assign ri_readData        =   readTag;

assign rw_isHaveFreeBlock =   isHaveFreeBlock;
assign rw_freeBlockNum    =   freeBlockNum;

/*****************************************************************************************************************
实例化module
*****************************************************************************************************************/
cache_rw_tag_ram #(
  .ADDR_WIDTH       (ADDR_WIDTH     ),
  .TAG_WIDTH        (TAG_WIDTH      )
)
cache_rw_tag_ram_inst0(
  .clk              (clk            ),
  .readAddress      (readAddress    ),
  .readChannel      (readChannel    ),
  .readTag          (readTag        ),
  .readHitTag       (readHitTag     ),
  .writeAddress     (writeAddress   ),
  .writeChannel     (writeChannel   ),
  .writeTag         (writeTag       ),
  .writeEnable      (writeEnable    ),
  .tag              (rw_tag         ),
  .isHit            (isHit          ),
  .hitBlockNum      (hitBlockNum    ),
  .isHaveFreeBlock  (isHaveFreeBlock),
  .freeBlockNum     (freeBlockNum   )
);

endmodule

/*****************************************************************************************************************
module:cache_rw_tag_ram
描述:存放cache块相关信息
*****************************************************************************************************************/
module cache_rw_tag_ram #(
  parameter ADDR_WIDTH,
            TAG_WIDTH
)(
  input                       clk,
  input [ADDR_WIDTH-1:0]      readAddress,
  input [1:0]                 readChannel,
  output[31:0]                readTag,
  output[31:0]                readHitTag,
  input [ADDR_WIDTH-1:0]      writeAddress,
  input [1:0]                 writeChannel,
  input [31:0]                writeTag,
  input                       writeEnable,
  input [TAG_WIDTH-1:0]  tag,
  output reg                  isHit,
  output[1:0]                 hitBlockNum,
  output                      isHaveFreeBlock,
  output[1:0]                 freeBlockNum
);

wire [31:0]                 rds[3:0];
wire [127:0]                rd,wd;
wire [15:0]                 wbe;
wire [3:0]                  bem;

assign {rds[3],rds[2],rds[1],rds[0]}  =   rd;
assign readTag                        =   rds[readChannel];
assign readHitTag                     =   rds[hitBlockNum];
assign wd                             =   {4{writeTag}};
assign bem                            =   4'd1 << writeChannel;
assign wbe                            =   {{4{bem[3]}},{4{bem[2]}},{4{bem[1]}},{4{bem[0]}}};

dualPortRam #(
	.WIDTH(32*4),		                            /*数据位宽*/
	.DEPTH(2**ADDR_WIDTH)	                      /*深度*/
)
dualPortRam_inst0_tagRam(
	.clk(clk),
	.readAddress(readAddress),	                /*读地址*/
	.readData(rd),							                /*读出的数据*/
	.writeAddress(writeAddress),                /*写地址*/
	.writeData(wd),				  	                  /*需要写入的数据*/
	.writeEnable(writeEnable),	                /*写使能*/
	.writeByteEnable(wbe)		                    /*字节使能信号*/
);

reg[3:0] addrEqual;

/*比较地址,判断是否命中*/
always @(*) begin:judgeHitBlock
  integer i;
  for(i=0;i<4;i=i+1) begin
    addrEqual[i]=(tag==rds[i][TAG_WIDTH-1:0])&&rds[i][TAG_WIDTH];/*标签相等，并且不是空块*/
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
assign isHaveFreeBlock=!(rds[0][TAG_WIDTH]
                        &rds[1][TAG_WIDTH]
                        &rds[2][TAG_WIDTH]
                        &rds[3][TAG_WIDTH]);

/*第几块是空闲的*/
assign freeBlockNum=rds[0][TAG_WIDTH]?2'd0:
                    rds[1][TAG_WIDTH]?2'd1:
                    rds[2][TAG_WIDTH]?2'd2:
                    rds[3][TAG_WIDTH]?2'd3:2'd0;
endmodule
