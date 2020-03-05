module fifo_sync_bypass #(
  parameter DEPTH=2,  /*允许为2,4,8,16*/
            WIDTH=32
)(
  input               clk,
  input               rest,
  output              full,
  output              empty,
  output              half,
  input               write,
  input               read,
  input  [WIDTH-1:0]  writeData,
  output [WIDTH-1:0]  readData
);

assign readData=writeData;

endmodule

