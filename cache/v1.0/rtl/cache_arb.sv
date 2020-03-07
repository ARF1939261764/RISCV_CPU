
`include "cache_define.v"

module cache_arb(
  input  logic clk,
  input  logic rest,
  /*s0从机接口:接到cache顶层模块的从机接口,供cpu访问*/
  input  logic [31:0] s0_address,
  input  logic [3:0]  s0_byteEnable,
  input  logic        s0_read,
  input  logic        s0_write,
  input  logic [31:0] s0_writeData,
  output logic        s0_waitRequest,
  output logic [31:0] s0_readData,
  output logic        s0_readDataValid,
  /*s1从机接口:接到cache_ri模块,供替换模块(rw module)访问总线使用*/
  input  logic [31:0] s1_address,
  input  logic [3:0]  s1_byteEnable,
  input  logic        s1_read,
  input  logic        s1_write,
  input  logic [31:0] s1_writeData,
  output logic        s1_waitRequest,
  output logic [31:0] s1_readData,
  output logic        s1_readDataValid,
  input  logic        s1_beginBurstTransfer,
  input  logic [7:0]  s1_burstCount,
  /*m0主机接口:接到cache_rw模块,访问cache模块*/
  output logic m0_address,
  output logic m0_byteEnable,
  output logic m0_read,
  output logic m0_write,
  output logic m0_writeData,
  input  logic m0_waitRequest,
  input  logic m0_readData,
  input  logic m0_readDataValid,
  /*m1主机接口:接到总线*/
  output logic m1_address,
  output logic m1_byteEnable,
  output logic m1_read,
  output logic m1_write,
  output logic m1_writeData,
  input  logic m1_waitRequest,
  input  logic m1_readData,
  input  logic m1_readDataValid,
  output logic m1_beginBurstTransfer,
  output logic m1_burstCount
);



endmodule
