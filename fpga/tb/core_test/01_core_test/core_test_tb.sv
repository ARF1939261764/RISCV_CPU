`timescale 1ns/100ps
module core_test_tb;

logic clk;
logic rest;
wire  io[31:0];
wire  tx;
core_test core_test_inst0 (
  .clk      (clk ),
  .rest     (rest),
  .gpio_io  (io),
  .uart_tx  (tx)
);

initial begin
  clk=0;
  rest=0;
  #100;
  rest=1;
end

always #10 clk=~clk;

endmodule