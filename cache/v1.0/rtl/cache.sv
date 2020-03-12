`include "cache_define.sv"

module cache #(
	parameter SIZE=8*1024,
            BLOCK_SIZE=64
)(
	/*时钟、复位*/
	input 				                               clk,
	input                                        rest,
	/*s0从机接口*/
	input	[31:0] 	                               s0_address,
	input	[3:0] 	                               s0_byteEnable,
	input					                               s0_read,
	output[31:0]	                               s0_readData,
	input					                               s0_write,
	input	[31:0]	                               s0_writeData,
	output				                               s0_waitRequest,
	output				                               s0_readDataValid,
  /*s1从机接口*/
	input	[31:0] 	                               s1_address,
	input	[3:0] 	                               s1_byteEnable,
	input					                               s1_read,
	output[31:0]	                               s1_readData,
	input					                               s1_write,
	input	[31:0]	                               s1_writeData,
	output				                               s1_waitRequest,
	output				                               s1_readDataValid,
	/*m0主机接口*/
	output[31:0]	                               m0_address,
	output[3:0] 	                               m0_byteEnable,
	output				                               m0_read,
	input	[31:0]	                               m0_readData,
	output				                               m0_write,
	output[31:0]	                               m0_writeData,
	input					                               m0_waitRequest,
	input					                               m0_readDataValid,
  output                                       m0_beginBurstTransfer,
  output[`CACHE_AVALON_BURST_COUNT_WIDTH-1:0]  m0_burstCount
);
/*******************************************************************************
位宽
*******************************************************************************/
localparam  BLOCK_ADDR_WIDTH     =$clog2(BLOCK_SIZE);
localparam  BLOCK_DEPTH         = BLOCK_SIZE/4;
localparam	DATA_RAM_ADDR_WIDTH	=	$clog2(SIZE/(32/8*4));/*8K:9*/
localparam	TAG_RAM_ADDR_WIDTH	=	$clog2(2**DATA_RAM_ADDR_WIDTH/BLOCK_DEPTH);/*8K:5*/
localparam	DRE_RAM_ADDR_WIDTH	=	$clog2(SIZE/32)+1;/*8K:9*/
localparam	TAG_WIDTH     			=	32-(DATA_RAM_ADDR_WIDTH+2);/*8K:21*/


/*******************************************************************************
wire
*******************************************************************************/
wire[31:0] 											av_arb_0_address;
wire[3:0]  											av_arb_0_byteEnable;
wire 			 											av_arb_0_read;
wire 			 											av_arb_0_write;
wire[31:0] 											av_arb_0_writeData;
wire       											av_arb_0_waitRequest;
wire       											av_arb_0_beginBurstTransfer;
wire[7:0]  											av_arb_0_burstCount;
wire[31:0] 											av_arb_0_readData;
wire       											av_arb_0_readDataValid;

wire[31:0] 											av_arb_1_address;
wire[3:0]  											av_arb_1_byteEnable;
wire 			 											av_arb_1_read;
wire 			 											av_arb_1_write;
wire[31:0] 											av_arb_1_writeData;
wire       											av_arb_1_waitRequest;
wire       											av_arb_1_beginBurstTransfer;
wire[7:0]  											av_arb_1_burstCount;
wire[31:0] 											av_arb_1_readData;
wire       											av_arb_1_readDataValid;

wire 														arb_bus_idle;

wire 														rw_cache_is_enable;
wire[31:0]                      rw_to_ctr_addr;

wire                            ctr_is_io_addr;
wire                            ctr_cache_is_enable;
wire[2:0]                       ctr_cmd;
wire                            ctr_cmd_ready;

wire 			 											ri_is_request;
wire[3:0]  											ri_cmd;
wire			 											ri_cmd_ready;
wire[31:0] 											ri_rsp_data;

wire[31:0]			 								rw_last_av_s0_address;
wire[3:0] 			 								rw_last_av_s0_byteEnable;
wire 			 			 								rw_last_av_s0_read;
wire 			 			 								rw_last_av_s0_write;
wire[31:0] 			 								rw_last_av_s0_writeData;
wire 						 								rw_isHit;
wire[1:0]        								rw_hitBlockNum;
wire             								rw_isHaveFreeBlock;
wire[1:0]				 								rw_freeBlockNum;

wire [DATA_RAM_ADDR_WIDTH-1:0]  data_ri_readAddress;
wire [1:0]                      data_ri_rwChannel;
wire [31:0]                     data_ri_readData;
wire [DATA_RAM_ADDR_WIDTH-1:0]  data_ri_writeAddress;
wire [3:0]                      data_ri_writeByteEnable;
wire                            data_ri_writeEnable;
wire [31:0]                     data_ri_writeData;

wire [TAG_RAM_ADDR_WIDTH-1:0]   tag_ri_readAddress;
wire [1:0]                      tag_ri_readChannel;
wire [31:0]                     tag_ri_readData;
wire [TAG_RAM_ADDR_WIDTH-1:0]   tag_ri_writeAddress;
wire [1:0]                      tag_ri_writeChannel;
wire                            tag_ri_writeEnable;
wire [31:0]                     tag_ri_writeData;

wire [DRE_RAM_ADDR_WIDTH-1:0]   dre_ri_readAddress;
wire [1:0]                      dre_ri_readChannel;
wire [7:0]                      dre_ri_readData;
wire [3:0]                      dre_ri_readRe;
wire [DRE_RAM_ADDR_WIDTH-1:0]   dre_ri_writeAddress;
wire [1:0]                      dre_ri_writeChannel;
wire                            dre_ri_writeEnable;
wire [7:0]                      dre_ri_writeData;

cache_arb cache_arb_inst0(
  .clk										  (clk														),
  .rest										  (rest														),
  /*s0从机接口:接到cache顶层模块的从机接口,供cpu访问*/
  .s0_address							  (s0_address											),
  .s0_byteEnable					  (s0_byteEnable									),
  .s0_read								  (s0_read												),
  .s0_write								  (s0_write												),
  .s0_writeData						  (s0_writeData										),
  .s0_waitRequest					  (s0_waitRequest									),
  .s0_readData						  (s0_readData										),
  .s0_readDataValid				  (s0_readDataValid								),
  /*s1从机接口:接到cache_ri模块,供替换模块(rw module)访问总线使用*/
  .s1_address							  (av_arb_1_address               ),
  .s1_byteEnable					  (av_arb_1_byteEnable            ),
  .s1_read								  (av_arb_1_read									),
  .s1_write								  (av_arb_1_write									),
  .s1_writeData						  (av_arb_1_writeData							),
  .s1_waitRequest					  (av_arb_1_waitRequest						),
  .s1_beginBurstTransfer    (av_arb_1_beginBurstTransfer 		),
  .s1_burstCount					  (av_arb_1_burstCount						),
  .s1_readData						  (av_arb_1_readData							),
  .s1_readDataValid				  (av_arb_1_readDataValid      		),
  /*m0主机接口:接到cache_rw模块,访问cache模块*/
  .m0_address							  (av_arb_0_address								),
  .m0_byteEnable					  (av_arb_0_byteEnable						),
  .m0_read								  (av_arb_0_read									),
  .m0_write								  (av_arb_0_write									),
  .m0_writeData						  (av_arb_0_writeData							),
  .m0_waitRequest					  (av_arb_0_waitRequest						),
  .m0_readData						  (av_arb_0_readData							),
  .m0_readDataValid				  (av_arb_0_readDataValid					),
  /*接到cache_rw模块*/
  .rw_bus_idle						  (arb_bus_idle                   ),
	.rw_cache_is_enable			  (rw_cache_is_enable							),
  /*m1主机接口:接到总线*/
  .m1_address							  (m0_address											),
  .m1_byteEnable					  (m0_byteEnable									),
  .m1_read								  (m0_read												),
  .m1_write								  (m0_write												),
  .m1_writeData						  (m0_writeData										),
  .m1_waitRequest					  (m0_waitRequest									),
  .m1_beginBurstTransfer	  (m0_beginBurstTransfer					),
  .m1_burstCount					  (m0_burstCount									),
  .m1_readData						  (m0_readData										),
  .m1_readDataValid				  (m0_readDataValid								)
);

cache_rw #(
  .DATA_RAM_ADDR_WIDTH		  (DATA_RAM_ADDR_WIDTH						),
  .TAG_RAM_ADDR_WIDTH			  (TAG_RAM_ADDR_WIDTH							),
  .DRE_RAM_ADDR_WIDTH			  (DRE_RAM_ADDR_WIDTH							),
  .TAG_WIDTH					      (TAG_WIDTH									    ),
  .BLOCK_ADDR_WIDTH         (BLOCK_ADDR_WIDTH               )
)cache_rw_inst0(  
  .clk										  (clk														),
  .rest										  (rest 													),
  
  .arb_address						  (av_arb_0_address								),
  .arb_byteEnable					  (av_arb_0_byteEnable						),
  .arb_read								  (av_arb_0_read									),
  .arb_readData						  (av_arb_0_readData  						),
  .arb_write							  (av_arb_0_write    							),
  .arb_writeData					  (av_arb_0_writeData 						),
  .arb_waitRequest				  (av_arb_0_waitRequest						),
  .arb_readDataValid			  (av_arb_0_readDataValid					),
  .arb_isEnableCache			  (rw_cache_is_enable							),
  .arb_bus_idle						  (arb_bus_idle               		),
  
  .ctr_address						  (rw_to_ctr_addr									),
  .ctr_isIOAddrBlock			  (ctr_is_io_addr									),
  .ctr_isEnableCache			  (ctr_cache_is_enable  					),
  .ri_isRequest						  (ri_is_request   						    ),
  .ri_cmd								    (ri_cmd                     		),
  .ri_cmd_ready					    (ri_cmd_ready										),
  .ri_rsp_data						  (ri_rsp_data							  		),
  .ri_last_arb_address	    (rw_last_av_s0_address					),
  .ri_last_arb_writeData    (rw_last_av_s0_writeData				),
  .ri_last_arb_byteEnable   (rw_last_av_s0_byteEnable				),
  .ri_last_arb_read				  (rw_last_av_s0_read							),
  .ri_last_arb_write			  (rw_last_av_s0_write						),
  .ri_isHit								  (rw_isHit												),
  .ri_hitBlockNum					  (rw_hitBlockNum									),
  .ri_isHaveFreeBlock			  (rw_isHaveFreeBlock							),
  .ri_freeBlockNum				  (rw_freeBlockNum								),
  
  .data_ri_readAddress		  (data_ri_readAddress            ),    
  .data_ri_rwChannel			  (data_ri_rwChannel              ),      
  .data_ri_readData				  (data_ri_readData               ),       
  .data_ri_writeAddress		  (data_ri_writeAddress           ),   
  .data_ri_writeByteEnable  (data_ri_writeByteEnable        ),
  .data_ri_writeEnable		  (data_ri_writeEnable            ),
  .data_ri_writeData			  (data_ri_writeData              ), 
  
  .tag_ri_readAddress			  (tag_ri_readAddress             ),
  .tag_ri_readChannel			  (tag_ri_readChannel             ),
  .tag_ri_readData				  (tag_ri_readData                ),
  .tag_ri_writeAddress		  (tag_ri_writeAddress            ),
  .tag_ri_writeChannel	    (tag_ri_writeChannel            ),
  .tag_ri_writeEnable			  (tag_ri_writeEnable             ),
  .tag_ri_writeData				  (tag_ri_writeData               ),

  .dre_ri_readAddress				(dre_ri_readAddress             ),
  .dre_ri_readChannel				(dre_ri_readChannel             ),
  .dre_ri_readData					(dre_ri_readData                ),
  .dre_ri_readRe						(dre_ri_readRe                  ),
  .dre_ri_writeAddress			(dre_ri_writeAddress            ),
  .dre_ri_writeChannel			(dre_ri_writeChannel            ),
  .dre_ri_writeEnable				(dre_ri_writeEnable             ),
  .dre_ri_writeData					(dre_ri_writeData               )
);

cache_ri #(
  .DATA_RAM_ADDR_WIDTH			(DATA_RAM_ADDR_WIDTH						),
  .TAG_RAM_ADDR_WIDTH				(TAG_RAM_ADDR_WIDTH							),
  .DRE_RAM_ADDR_WIDTH				(DRE_RAM_ADDR_WIDTH							),
  .TAG_WIDTH						    (TAG_WIDTH									    ),
  .BLOCK_ADDR_WIDTH         (BLOCK_ADDR_WIDTH               )
)
cache_ri_inst0(
  .clk											(clk                            ),
  .rest											(rest                           ),

  .av_m0_address						(av_arb_1_address							  ),
  .av_m0_byteEnable					(av_arb_1_byteEnable					  ),
  .av_m0_read								(av_arb_1_read								  ),
  .av_m0_write							(av_arb_1_write								  ),
  .av_m0_writeData					(av_arb_1_writeData						  ),
  .av_m0_waitRequest				(av_arb_1_waitRequest					  ),
  .av_m0_beginBurstTransfer	(av_arb_1_beginBurstTransfer	  ),
  .av_m0_burstCount					(av_arb_1_burstCount					  ),
  .av_m0_readData						(av_arb_1_readData						  ),
  .av_m0_readDataValid			(av_arb_1_readDataValid				  ),

  .ctr_cmd									(ctr_cmd             					  ),
  .ctr_cmd_ready						(ctr_cmd_ready                  ),
  .ctr_isEnableCache				(ctr_cache_is_enable  				  ),

  .rw_cmd										(ri_cmd												  ),
  .rw_cmd_ready							(ri_cmd_ready									  ),
  .rw_isRequest							(ri_is_request								  ),
  .rw_rsp_data							(ri_rsp_data									  ),
  .rw_last_av_s0_address		(rw_last_av_s0_address				  ),
  .rw_last_av_s0_writeData	(rw_last_av_s0_writeData			  ),
  .rw_last_av_s0_byteEnable	(rw_last_av_s0_byteEnable			  ),
  .rw_last_av_s0_read				(rw_last_av_s0_read						  ),
  .rw_last_av_s0_write			(rw_last_av_s0_write					  ),
  .rw_isHit									(rw_isHit											  ),
  .rw_hitBlockNum						(rw_hitBlockNum								  ),
  .rw_isHaveFreeBlock				(rw_isHaveFreeBlock						  ),
  .rw_freeBlockNum					(rw_freeBlockNum							  ),

  .data_ri_readAddress			(data_ri_readAddress            ),
  .data_ri_rwChannel				(data_ri_rwChannel              ),
  .data_ri_readData					(data_ri_readData               ),
  .data_ri_writeAddress			(data_ri_writeAddress           ),
  .data_ri_writeByteEnable	(data_ri_writeByteEnable        ),
  .data_ri_writeEnable			(data_ri_writeEnable            ),
  .data_ri_writeData				(data_ri_writeData              ),

  .tag_ri_readAddress				(tag_ri_readAddress             ),
  .tag_ri_readChannel				(tag_ri_readChannel             ),
  .tag_ri_readData					(tag_ri_readData                ),
  .tag_ri_writeAddress			(tag_ri_writeAddress            ),
  .tag_ri_writeChannel			(tag_ri_writeChannel            ),
  .tag_ri_writeEnable				(tag_ri_writeEnable             ),
  .tag_ri_writeData					(tag_ri_writeData               ),

  .dre_ri_readAddress				(dre_ri_readAddress             ),
  .dre_ri_readChannel				(dre_ri_readChannel             ),
  .dre_ri_readData					(dre_ri_readData                ),
  .dre_ri_readRe						(dre_ri_readRe                  ),
  .dre_ri_writeAddress		  (dre_ri_writeAddress            ),
  .dre_ri_writeChannel			(dre_ri_writeChannel            ),
  .dre_ri_writeEnable				(dre_ri_writeEnable             ),
  .dre_ri_writeData					(dre_ri_writeData               )
);

cache_ctr #(
  .ADDR_BLOCK_NUM           (4                              )
)
cache_ctr_inst0(
  .clk                      (clk                            ),
  .rest                     (rest                           ),
  /*s0从机接口*/
  .s0_address               (s1_address                     ),
  .s0_byteEnable            (s1_byteEnable                  ),
  .s0_read                  (s1_read                        ),
  .s0_readData              (s1_readData                    ),
  .s0_write                 (s1_write                       ),
  .s0_writeData             (s1_writeData                   ),
  .s0_waitRequest           (s1_waitRequest                 ),
  .s0_readDataValid         (s1_readDataValid               ),
  /*其它*/
  .address                  (rw_to_ctr_addr                 ),
  .isIOAddrBlock            (ctr_is_io_addr                 ),
  .isEnableCache            (ctr_cache_is_enable            ),
  .cmd                      (ctr_cmd                        ),
  .cmd_ready                (ctr_cmd_ready                  )
);

initial begin
  $display("DATA_RAM_ADDR_WIDTH=%d",DATA_RAM_ADDR_WIDTH);
  $display("TAG_RAM_ADDR_WIDTH =%d",TAG_RAM_ADDR_WIDTH );
  $display("DRE_RAM_ADDR_WIDTH =%d",DRE_RAM_ADDR_WIDTH );
  $display("TAG_WIDTH         =%d" ,TAG_WIDTH          );
end

endmodule
