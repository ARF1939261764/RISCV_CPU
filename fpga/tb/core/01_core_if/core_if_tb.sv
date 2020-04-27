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
  .SIZE     (32*1024),
  .INIT_FILE("../../../tb/core/file/ram_data_01.txt")
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
  $display("jump to 32'h10");
  flush_en=1;
  jump_en=1;
  jump_addr=32'h10;
  @(posedge clk);
  jump_en=0;
  flush_en=0;
  #1000;
  @(posedge clk);
  $display("jump to 32'h64");
  bp_jump_en=1;
  bp_jump_addr=32'h64;
  @(posedge clk);
  bp_jump_en=0;
end

always @(posedge clk) begin
  if(fd_valid) begin
    $display("pc=%x,istr=%x,type=%s",fd_pc,(fd_istr[1:0]==2'd3)?fd_istr:fd_istr[15:0],(fd_istr[1:0]==2'd3)?"i":"c");
  end
end

endmodule


