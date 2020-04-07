`timescale 1ns/100ps

module core_if_tb;

logic         clk;
logic         rest;
i_avl_bus     avl_m0();
logic[31:0]   csr_mepc;
logic[31:0]   jump_addr;
logic         jump_en;
logic         flush_en;
logic[31:0]   bp_istr;
logic[31:0]   bp_pc;
logic[31:0]   bp_jump_addr;
logic         bp_jump_en;
logic[31:0]   fd_istr;
logic[31:0]   fd_pc;
logic         fd_valid;
logic         fd_jump;
logic         fd_ready;
logic         ctr_stop;           /*停止cpu*/

/*取指模块*/
core_if #(
  .REST_ADDR(0)
)
core_if_inst0(
  .*
);

/*sdram模块*/
sdram_sim_model #(
  .SIZE(32*1024)
)
sdram_sim_model_inst0(
  .*
);

initial begin
  clk=0;
  rest=1;
  csr_mepc=32'h42;
  jump_addr=0;
  jump_en=0;
  flush_en=0;
  bp_jump_addr=0;
  bp_jump_en=0;
  fd_ready=1;
  ctr_stop=0;
  
end

always #10 clk=~clk;

initial begin
  #10   rest=0;
  #100  rest=1;
  #1000;
  @(posedge clk);
  $display("jump to 32'h8b0");
  flush_en=1;
  jump_en=1;
  jump_addr=32'h8b0;
  @(posedge clk);
  jump_en=0;
  flush_en=0;
  #1000;
  @(posedge clk);
  $display("jump to 32'h948");
  bp_jump_en=1;
  bp_jump_addr=32'h948;
  @(posedge clk);
  bp_jump_en=0;
end

always @(posedge clk) begin
  if(fd_valid) begin
    $display("pc=%x,istr=%x,type=%s",fd_pc,(fd_istr[1:0]==2'd3)?fd_istr:fd_istr[15:0],(fd_istr[1:0]==2'd3)?"i":"c");
  end
end

endmodule

module sdram_sim_model #(
  parameter SIZE = 32*1024
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
  $readmemh("file/ram_data_01.txt",ram);
end

endmodule
