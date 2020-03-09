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
