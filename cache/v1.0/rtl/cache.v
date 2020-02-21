module cache #(
	parameter SIZE=2*1024
)(
	/*时钟、复位*/
	clk,
	rest,
	/*s0从机接口*/
	s0_address,
	s0_byteEnable,
	s0_read,
	s0_readData,
	s0_write,
	s0_writeData,
	s0_waitRequest,
	s0_readDataValid,
	/*s1从机接口*/
	s1_address,
	s1_byteEnable,
	s1_read,
	s1_readData,
	s1_write,
	s1_writeData,
	s1_waitRequest,
	s1_readDataValid,
	/*m0主机接口*/
	m0_address,
	m0_byteEnable,
	m0_read,
	m0_readData,
	m0_write,
	m0_writeData,
	m0_waitRequest,
	m0_readDataValid
);
/*时钟、复位*/
input 				clk,rest;
/*s0从机接口*/
input	[31:0] 	s0_address;
input	[3:0] 	s0_byteEnable;
input					s0_read;
output[31:0]	s0_readData;
input					s0_write;
input	[31:0]	s0_writeData;
output				s0_waitRequest;
output				s0_readDataValid;
/*s1从机接口*/
input	[31:0]	s1_address;
input	[3:0] 	s1_byteEnable;
input					s1_read;
output[31:0]	s1_readData;
input					s1_write;
input	[31:0]	s1_writeData;
output				s1_waitRequest;
output				s1_readDataValid;
/*m0主机接口*/
output[31:0]	m0_address;
output[3:0] 	m0_byteEnable;
output				m0_read;
input	[31:0]	m0_readData;
output				m0_write;
output[31:0]	m0_writeData;
input					m0_waitRequest;
input					m0_readDataValid;


endmodule
