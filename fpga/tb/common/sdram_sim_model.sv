module sdram_sim_model #(
  parameter        SIZE = 32*1024,
            string INIT_FILE=""
)(
  input  logic        clk,
  i_avl_bus.slave     avl_m0
);
localparam ADD_WIDTH=($clog2(SIZE)+10)-2;
logic [3:0][7:0] ram[SIZE*1024-1:0];
always@(posedge clk)
begin
	if(avl_m0.write) begin
		if(avl_m0.byte_en[0]) ram[avl_m0.address[ADD_WIDTH+1:2]][0] <= avl_m0.write_data[7:0];
		if(avl_m0.byte_en[1]) ram[avl_m0.address[ADD_WIDTH+1:2]][1] <= avl_m0.write_data[15:8];
		if(avl_m0.byte_en[2]) ram[avl_m0.address[ADD_WIDTH+1:2]][2] <= avl_m0.write_data[23:16];
		if(avl_m0.byte_en[3]) ram[avl_m0.address[ADD_WIDTH+1:2]][3] <= avl_m0.write_data[31:24];
  end 
  if(avl_m0.read) begin
    avl_m0.read_data<=ram[avl_m0.address[ADD_WIDTH+1:2]];
  end
  avl_m0.read_data_valid<=avl_m0.read;
end
assign avl_m0.request_ready=1;

initial begin
  if(INIT_FILE.len>0) begin
    $readmemh(INIT_FILE,ram);
  end
end

endmodule