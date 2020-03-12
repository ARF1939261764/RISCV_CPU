`timescale 1ns/100ps 

module cache_tb_rand_test;

/*时钟、复位*/
logic 				   clk;
logic            rest;
/*s0从机接口*/ 
logic [31:0] 	   s0_address;
logic [3:0] 	   s0_byteEnable;
logic 				   s0_read;
logic [31:0]	   s0_readData;
logic 				   s0_write;
logic [31:0]	   s0_writeData;
logic 				   s0_waitRequest;
logic 				   s0_readDataValid;
/*s1从机接口*/ 
logic [31:0] 	   s1_address;
logic [3:0] 	   s1_byteEnable;
logic 				   s1_read;
logic [31:0]	   s1_readData;
logic 				   s1_write;
logic [31:0]	   s1_writeData;
logic 				   s1_waitRequest;
logic 				   s1_readDataValid;
/*m0主机接口*/ 
logic [31:0]	   m0_address;
logic [3:0] 	   m0_byteEnable;
logic 				   m0_read;
logic [31:0]	   m0_readData;
logic 				   m0_write;
logic [31:0]	   m0_writeData;
logic 				   m0_waitRequest;
logic 				   m0_readDataValid;
logic            m0_beginBurstTransfer;
logic [8-1:0]  	 m0_burstCount;

/*******************************************************************
cache模块实例化
*******************************************************************/
cache #(
	.SIZE(8*1024),
	.BLOCK_SIZE(256)
)
cache_inst0(
	.*
);

/*******************************************************************
sdram模拟
*******************************************************************/
sdram_sim_model sdram_sim_model_inst0(
  .clk              (clk              ),
  .s0_address       (m0_address       ),
  .s0_byteEnable    (m0_byteEnable    ),
  .s0_read          (m0_read          ),
  .s0_readData      (m0_readData      ),
  .s0_write         (m0_write         ),
  .s0_writeData     (m0_writeData     ),
  .s0_waitRequest   (m0_waitRequest   ),
  .s0_readDataValid (m0_readDataValid )
);

/*******************************************************************
测试过程
*******************************************************************/
initial begin
	int i;
	reg[31:0] data,temp,addr;
	reg[3:0] byteEnable;
	#10 system_rest();
	$random(12021961);
	wait(s0_waitRequest==0);
	forever begin
    temp=$random();
		addr=get_rand_addr();
		byteEnable={$random()}%16;
		data=$random();
		if(temp[0]) begin
			writeData(addr[24:0],byteEnable,data);
			$display("i=%d,write:address:%x,data=%x,byte=%1x",i,addr[24:0],data,byteEnable);
		end
		addr=get_rand_addr();
		byteEnable={$random()}%16;
		if(temp[1]) begin
			readData(addr[24:0],byteEnable,data);
			$display("i=%d,read :address:%x,data=%x,byte=%1x",i,addr[24:0],data,byteEnable);
		end
		i++;
  end
end

/*******************************************************************
获取一次随机地址
*******************************************************************/
reg signed[31:0] temp_addr_a=0,temp_addr_b=0,temp_addr=0;
reg[4:0] div_count=0;
function[31:0] get_rand_addr();
	temp_addr+=$random()%64+(div_count==0?1:0);
	if(temp_addr<0)  begin
		temp_addr=0;
	end
	div_count++;
	return temp_addr[31:2]<<2;
endfunction

/*******************************************************************
系统复位任务
*******************************************************************/
task system_rest();
	#0   rest=0;
	#100 rest=1;
endtask

/*******************************************************************
赋初值
*******************************************************************/
initial begin
	rest=0;
	clk=0;

	s0_address=0;
	s0_byteEnable=0;
	s0_read=0;
	s0_write=0;
	s0_writeData=0;

	s1_address=0;
	s1_byteEnable=0;
	s1_read=0;
	s1_write=0;
	s1_writeData=0;

end

/*******************************************************************
产生时钟
*******************************************************************/
always begin
	#5 clk=~clk;
end

/*******************************************************************
ram，和模拟的sdram读出的数据对比
*******************************************************************/
logic [3:0][7:0] ram[32*1024*1024-1:0];
initial begin
  int i;
  for(i=0;i<32*1024*1024;i++) begin
    ram[i]=0;
  end
end

/*******************************************************************
读cache
*******************************************************************/
task readData(
	input[31:0] addr,
	input[3:0]  byteEnable,
	output[31:0] data
);
  logic[31:0] rd;
  task_s0_readData(addr,byteEnable,rd);
	data=rd;
	if(
		((rd[31:24]!=ram[addr/4][3])&&byteEnable[3])||
		((rd[23:16]!=ram[addr/4][2])&&byteEnable[2])||
		((rd[15:8] !=ram[addr/4][1])&&byteEnable[1])||
		((rd[7:0]  !=ram[addr/4][0])&&byteEnable[0])
	) begin
    $error("error:addr:%x,sdram=%x,ram=%x",addr,data,ram[addr/4]);
    $stop();
  end
endtask

/*******************************************************************
写cache
*******************************************************************/
localparam ADD_WIDTH=($clog2(32*1024)+10)-2;
task writeData(
	input[31:0] addr,
	input[3:0]  byteEnable,
	input[31:0] data
);
  task_s0_writeData(addr,byteEnable,data);
  if(byteEnable[0]) ram[addr[ADD_WIDTH+1:2]][0] <= data[7:0];
  if(byteEnable[1]) ram[addr[ADD_WIDTH+1:2]][1] <= data[15:8];
  if(byteEnable[2]) ram[addr[ADD_WIDTH+1:2]][2] <= data[23:16];
  if(byteEnable[3]) ram[addr[ADD_WIDTH+1:2]][3] <= data[31:24];
endtask

/*******************************************************************
读cache
*******************************************************************/
task task_s0_readData(
	input[31:0] addr,
	input[3:0]  byteEnable,
	output[31:0] data
);
	@(posedge clk);
	s0_address			=  addr;
	s0_byteEnable		=  byteEnable;
	s0_read					=	 1;
	s0_write				=  0;
	forever begin
		@(posedge clk);
		if(!s0_waitRequest) begin
			s0_read=0;
			break;
		end
	end
	forever begin
		@(posedge clk);
		if(s0_readDataValid) begin
			break;
		end
	end
	data=s0_readData;
endtask

/*******************************************************************
写cache
*******************************************************************/
task task_s0_writeData(
	input[31:0] addr,
	input[3:0]  byteEnable,
	input[31:0] data
);
	s0_address			=  addr;
	s0_byteEnable		=  byteEnable;
	s0_read					=	 0;
	s0_write				=  1;
	s0_writeData		=data;
	while (1) begin
		@(posedge clk);
		if(!s0_waitRequest) begin
			s0_write=0;
			break;
		end
	end
endtask


endmodule


module sdram_sim_model #(
  parameter SIZE = 32*1024
)(
  input  logic        clk,
  input  logic [31:0] s0_address,
  input  logic [3:0]  s0_byteEnable,
  input  logic 			  s0_read,
  output logic [31:0] s0_readData,
  input  logic 			  s0_write,
  input  logic [31:0] s0_writeData,
  output logic 			  s0_waitRequest,
  output logic 			  s0_readDataValid
);
localparam ADD_WIDTH=($clog2(SIZE)+10)-2;
logic [3:0][7:0] ram[SIZE*1024-1:0];
always@(posedge clk)
begin
	if(s0_write) begin
		if(s0_byteEnable[0]) ram[s0_address[ADD_WIDTH+1:2]][0] <= s0_writeData[7:0];
		if(s0_byteEnable[1]) ram[s0_address[ADD_WIDTH+1:2]][1] <= s0_writeData[15:8];
		if(s0_byteEnable[2]) ram[s0_address[ADD_WIDTH+1:2]][2] <= s0_writeData[23:16];
		if(s0_byteEnable[3]) ram[s0_address[ADD_WIDTH+1:2]][3] <= s0_writeData[31:24];
  end 
  if(s0_read) begin
    s0_readData<=ram[s0_address[ADD_WIDTH+1:2]];
  end
  s0_readDataValid<=s0_read;
end
assign s0_waitRequest=0;

initial begin
  int i;
  for(i=0;i<SIZE*1024;i++) begin
    ram[i]=0;
  end
end

endmodule

