module cache_arb(
  clk,
  rest,
  /*s0从机接口:接到cache顶层模块的从机接口,供cpu访问*/
  s0_address,
  s0_byteEnable,
  s0_read,
  s0_write,
  s0_writeData,
  s0_waitRequest,
  s0_readData,
  s0_readDataValid,
  /*s1从机接口:接到cache_ri模块,供替换模块(rw module)访问总线使用*/
  s1_address,
  s1_byteEnable,
  s1_read,
  s1_write,
  s1_writeData,
  s1_waitRequest,
  s1_readData,
  s1_readDataValid,
  /*m0主机接口:接到cache_rw模块,访问cache模块*/
  m0_address,
  m0_byteEnable,
  m0_read,
  m0_write,
  m0_writeData,
  m0_waitRequest,
  m0_readData,
  m0_readDataValid,
  /*m1主机接口:接到总线*/
  m1_address,
  m1_byteEnable,
  m1_read,
  m1_write,
  m1_writeData,
  m1_waitRequest,
  m1_readData,
  m1_readDataValid,
  m1_beginBurstTransfer,
  m1_burstCount
);



endmodule
