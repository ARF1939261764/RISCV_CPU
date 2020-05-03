/******************************************************
文件名:dualPortRam.v
功能:
	提供数据位宽、深度可定制的双端口RAM

Tab大小:2个空格

V0.1:2020年2月15日

最后更新日期:
	2020年2月15日
******************************************************/
`include "../define/define.sv"

module dualPortRam #(
	parameter WIDTH=32,		/*数据位宽*/
						DEPTH=1024	/*深度*/
)(
	clk,
	readAddress,					/*读地址*/
	readData,							/*读出的数据*/
	writeAddress,					/*写地址*/
	writeData,						/*需要写入的数据*/
	writeEnable,					/*写使能*/
	writeByteEnable				/*字节使能信号*/
);
/********************************************************
地址宽度
********************************************************/
localparam ADDR_WIDTH=$clog2(DEPTH);

/********************************************************
输入输出端口
********************************************************/
input 	logic 										clk;
input		logic [ADDR_WIDTH-1:0] 		readAddress;
output	logic [WIDTH-1:0] 				readData;
input		logic [ADDR_WIDTH-1:0] 		writeAddress;
input		logic [WIDTH/8-1:0][7:0] 	writeData;
input 	logic 										writeEnable;
input		logic [(WIDTH+7)/8-1:0] 	writeByteEnable;
/********************************************************
生成RAM(需要根据不同FPGA类型进行适配)
********************************************************/
`ifdef FPGA_TYPE_ALTERA
	/*---生成Altrera的RAM-------------------------*/
	altsyncram	altsyncram_component (
			.address_a (writeAddress),			/*端口a写地址*/
			.address_b (readAddress),				/*端口b写地址*/
			.byteena_a (writeByteEnable),		/*端口a字节使能*/
			.clock0 (clk),									/*时钟*/
			.data_a (writeData),						/*端口a写数据*/
			.wren_a (writeEnable),					/*端口a写使能*/
			.q_b (readData),								/*端口a读数据*/
			.aclr0 (1'b0),									/*clear信号*/
			.aclr1 (1'b0),									/*clear信号*/
			.addressstall_a (1'b0),					/*地址时钟使能,低电平有效*/
			.addressstall_b (1'b0),					/*地址时钟使能,低电平有效*/
			.byteena_b (1'b1),							/*端口b字节使能*/
			.clock1 (1'b1),									/*时钟*/
			.clocken0 (1'b1),								/*时钟使能*/
			.clocken1 (1'b1),								/*时钟使能*/
			.clocken2 (1'b1),								/*时钟使能*/
			.clocken3 (1'b1),								/*时钟使能*/
			.data_b ({WIDTH{1'b1}}),				/*端口b写数据*/
			.eccstatus (),									/*标识是否有可纠错bit*/
			.q_a (),												/*端口a数据输出*/
			.rden_a (1'b1),									/*读使能*/
			.rden_b (1'b1),									/*端口b读使能*/
			.wren_b (1'b0));								/*端口b写使能*/
	defparam
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.byte_size = 8,
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_input_b = "BYPASS",
		altsyncram_component.clock_enable_output_b = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone 10 LP",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = DEPTH,
		altsyncram_component.numwords_b = DEPTH,
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.widthad_a = ADDR_WIDTH,					/*地址宽度*/
		altsyncram_component.widthad_b = ADDR_WIDTH,
		altsyncram_component.width_a = WIDTH,									/*数据宽度*/
		altsyncram_component.width_b = WIDTH,
		altsyncram_component.width_byteena_a = (WIDTH+7)/8;		/*字节使能信号宽度*/
`elsif FPGA_TYPE_XILINX
	/*---生成Xilinx的RAM-------------------------*/
	/*
	...
	*/
`elsif FPGA_TYPE_NULL
	/*---生成verilog描述的RAM-------------------------*/
	logic [WIDTH/8-1:0][7:0] ram[DEPTH];
	initial begin:ram_init_block
		int i;
		for(i=0;i<DEPTH;i++) begin
			ram[i]=0;
		end
	end
	always@(posedge clk) begin:ram_rw_block
    int i;
    for(i=0;i<WIDTH/8;i++) begin
      if(writeByteEnable[i]&&writeEnable) begin
        ram[writeAddress][i] <= writeData[i];
      end
    end
		readData<=ram[readAddress];
	end
`endif
endmodule
