/*****************************************************************************************************************
module:cache_rw_dre
存放cache块中每个byte是否可读的信息
*****************************************************************************************************************/
module cache_rw_dre #(
  parameter ADDR_WIDTH=9
)(
  input                   clk,
  input                   sel,
  /*连到rw*/
  input  [ADDR_WIDTH-1:0] rw_readAddress,
  input  [1:0]            rw_readChannel,
  output [3:0]            rw_readRe,
  input  [ADDR_WIDTH-1:0] rw_writeAddress,
  input  [1:0]            rw_writeChannel,
  input                   rw_writeEnable,
  input  [3:0]            rw_writeRe,
  /*连到ri*/
  input  [ADDR_WIDTH-1:0] ri_readAddress,
  input  [1:0]            ri_readChannel,
  output [7:0]            ri_readData,
  output [3:0]            ri_readRe,
  input  [ADDR_WIDTH-1:0] ri_writeAddress,
  input  [1:0]            ri_writeChannel,
  input                   ri_writeEnable,
  input  [7:0]            ri_writeData
);
/*****************************************************************************************************************
wire and reg
*****************************************************************************************************************/
wire [ADDR_WIDTH-1:0]   readAddress;
wire [1:0]              readChannel;
wire [3:0]              readRe;
wire [7:0]              readReAll;
wire [ADDR_WIDTH-1:0]   writeAddress;
wire [1:0]              writeChannel;
wire [7:0]              writeData;
wire                    writeEnable;
wire [7:0]              wre;


/*****************************************************************************************************************
连线
*****************************************************************************************************************/
assign readAddress      =   sel?ri_readAddress   : rw_readAddress;
assign readChannel      =   sel?ri_readChannel   : rw_readChannel;
assign writeAddress     =   sel?ri_writeAddress  : rw_writeAddress;
assign writeChannel     =   sel?ri_writeChannel  : rw_writeChannel;
assign writeData        =   sel?ri_writeData     : wre;
assign writeEnable      =   sel?ri_writeEnable   : rw_writeEnable;

assign wre              =   readReAll|({{4{writeAddress[0]}},{4{!writeAddress[0]}}}&{2{rw_writeRe}});
assign rw_readRe        =   readRe;
assign ri_readData      =   readReAll;
assign ri_readRe        =   readRe;

/*****************************************************************************************************************
实例化module
*****************************************************************************************************************/
cache_rw_dre_ram #(
  .ADDR_WIDTH(ADDR_WIDTH)
)cache_rw_dre_ram_inst0(
  .clk          (clk            ),
  .readAddress  (readAddress    ),
  .readChannel  (readChannel    ),
  .readRe       (readRe         ),
  .readReAll    (readReAll      ),
  .writeAddress (writeAddress   ),
  .writeChannel (writeChannel   ),
  .writeRe      (writeData      ),
  .writeEnable  (writeEnable    )
);

endmodule

/*****************************************************************************************************************
module:cache_rw_dre_ram
描述:存放每个字节是否可读的信息
*****************************************************************************************************************/
module cache_rw_dre_ram #(
  parameter ADDR_WIDTH
)(
  input                   clk,
  input [ADDR_WIDTH-1:0]  readAddress,
  input [1:0]             readChannel,
  output[3:0]             readRe,
  output[7:0]             readReAll,
  input [ADDR_WIDTH-1:0]  writeAddress,
  input [1:0]             writeChannel,
  input [7:0]             writeRe,
  input                   writeEnable
);
wire         [31:0] rd,wd;
wire         [7:0] rds[3:0];
reg          last_addr_bit0;
reg          last_is_write_during_read;
reg  [7:0]   last_writeRe;

assign {rds[3],rds[2],rds[1],rds[0]}=rd;

assign readRe=last_addr_bit0?readReAll[7:4]:readReAll[3:0];
assign readReAll=last_is_write_during_read?last_writeRe:rds[readChannel];

assign wd={4{writeRe}};

always @(posedge clk) begin
  last_addr_bit0<=readAddress[0];
  last_is_write_during_read<=(readAddress[ADDR_WIDTH-1:1]==writeAddress[ADDR_WIDTH-1:1])&&(readChannel==writeChannel)&&writeEnable;
  last_writeRe<=writeRe;
end

dualPortRam #(
	.WIDTH(32),		                                /*数据位宽*/
	.DEPTH(2**(ADDR_WIDTH-1))	                    /*深度*/
)
dualPortRam_inst0_tagRam(
	.clk(clk),
	.readAddress(readAddress[ADDR_WIDTH-1:1]),	  /*读地址*/
	.readData(rd),							                  /*读出的数据*/
	.writeAddress(writeAddress[ADDR_WIDTH-1:1]),  /*写地址*/
	.writeData(wd),						                    /*需要写入的数据*/
	.writeEnable(writeEnable),	                  /*写使能*/
	.writeByteEnable(4'd1<<writeChannel)		      /*字节使能信号*/
);

endmodule
