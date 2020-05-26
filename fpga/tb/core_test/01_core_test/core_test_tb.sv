`timescale 1ns/100ps
module core_test_tb;

logic clk;
logic rest;
wire  io[31:0];
core_test core_test_inst0 (
  .clk (clk ),
  .rest(rest),
  .io  (io)
);

initial begin
  clk=0;
  rest=0;
  #100;
  rest=1;
end

always #10 clk=~clk;

endmodule