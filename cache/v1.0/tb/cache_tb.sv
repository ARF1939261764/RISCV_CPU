`timescale 1ns/100ps 

module cache_tb;

/*时钟、复位*/
logic 				                               clk;
logic                                        rest;
/*s0从机接口*/ 
logic [31:0] 	                               s0_address;
logic [3:0] 	                               s0_byteEnable;
logic 				                               s0_read;
logic [31:0]	                               s0_readData;
logic 				                               s0_write;
logic [31:0]	                               s0_writeData;
logic 				                               s0_waitRequest;
logic 				                               s0_readDataValid;
/*s1从机接口*/ 
logic [31:0] 	                               s1_address;
logic [3:0] 	                               s1_byteEnable;
logic 				                               s1_read;
logic [31:0]	                               s1_readData;
logic 				                               s1_write;
logic [31:0]	                               s1_writeData;
logic 				                               s1_waitRequest;
logic 				                               s1_readDataValid;
/*m0主机接口*/ 
logic [31:0]	                               m0_address;
logic [3:0] 	                               m0_byteEnable;
logic 				                               m0_read;
logic [31:0]	                               m0_readData;
logic 				                               m0_write;
logic [31:0]	                               m0_writeData;
logic 				                               m0_waitRequest;
logic 				                               m0_readDataValid;
logic                                        m0_beginBurstTransfer;
logic [8-1:0]  															 m0_burstCount;

cache #(
	.SIZE(8*1024)
)
cache_inst0(
	.*
);

sdram_sim_model sdram_sim_model_inst0(
  .clk(clk),
  .s0_address(m0_address),
  .s0_byteEnable(m0_byteEnable),
  .s0_read(m0_read),
  .s0_readData(m0_readData),
  .s0_write(m0_write),
  .s0_writeData(m0_writeData),
  .s0_waitRequest(m0_waitRequest),
  .s0_readDataValid(m0_readDataValid)
);

reg[31:0] data;
initial begin
	int i;
	#10 system_rest();
	for(i=0;i<1000;i++) begin
		task_s0_readData(4*i,4'b1111,data);
		if(data!=i*i) begin
			$error("read data err:%d",i);
      $stop();
		end
	end
end

task system_rest();
	#0   rest=0;
	#100 rest=1;
endtask

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

	m0_waitRequest=0;
	m0_readDataValid=0;
end

always begin
	#5 clk=~clk;
end

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
	while (1) begin
		@(posedge clk);
		if(!s0_waitRequest) begin
			s0_read=0;
			break;
		end
	end
	while (1) begin
		@(posedge clk);
		if(s0_readDataValid) begin
			break;
		end
	end
	data=s0_readData;
	$display("task_s0_readData return data:%x",data);
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
  for(i=0;i<1000;i++) begin
    ram[i]=i*i;
  end
end

endmodule

