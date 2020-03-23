`timescale   1ns/100ps
/******************************************************************
cache_io_tb:cache_io Testbench
******************************************************************/
module cache_io_tb();

/*************************************************
地址块个数
**************************************************/
localparam ioAddrBlockNum=4;

/**************************************************
port
**************************************************/
reg         clk,rest;
reg[31:0]   s0_address;
reg         s0_read;
wire[31:0]  s0_readData;
reg         s0_write;
reg[31:0]   s0_writeData;
wire        s0_waitRequest;
wire        s0_readDataValid;
reg[31:0]   address;
wire        isIOAddrBlock;
wire[1:0]   cmd;
wire        cmd_valid;
reg         cmd_ready;

/**************************************************
module instance
**************************************************/
cache_io #(
  .ioAddrBlockNum(ioAddrBlockNum)
)cache_io_inst(
  .clk(clk),
  .rest(rest),
  /*s0从机接口*/
  .s0_address(s0_address),
  .s0_byteEnable(0),
  .s0_read(s0_read),
  .s0_readData(s0_readData),
  .s0_write(s0_write),
  .s0_writeData(s0_writeData),
  .s0_waitRequest(s0_waitRequest),
  .s0_readDataValid(s0_readDataValid),
  /*其它*/
  .address(address),
  .isIOAddrBlock(isIOAddrBlock),
  .cmd(cmd),
  .cmd_valid(cmd_valid),
  .cmd_ready(cmd_ready)
);

/***************************************************
write task
***************************************************/
task writeReg;
  input[31:0] address;
  input[31:0] data;
  begin
    s0_write=1;
    s0_read=0;
    s0_address=address;
    s0_writeData=data;
    wait(s0_waitRequest==0);
    @(posedge clk);
    s0_write=0;
  end
endtask

/***************************************************
read task
***************************************************/
task ReadReg;
  input[31:0] address;
  output[31:0] data;
  begin
    s0_write=0;
    s0_read=1;
    s0_address=address;
    wait(s0_waitRequest==0);
    @(posedge clk);
    s0_read=0;
    wait(s0_readDataValid==1);
    @(posedge clk);
    data=s0_readData;
  end
endtask

/***************************************************
test
***************************************************/
integer i;
reg[31:0] data;
initial begin
  clk=0;
  rest=1;
  address=100;
  cmd_ready=0;
  #100 rest=0;
  #100 rest=1;
  for(i=0;i<=ioAddrBlockNum*2;i=i+1) begin
    writeReg(i*4,i*i<<10);
  end
  writeReg(0,2<<16);
  for(i=0;i<=ioAddrBlockNum*2;i=i+1) begin
    ReadReg(i*4,data);
    $display("%d\n",data[31:10]);
  end
end

initial begin
  wait(cmd_valid==1);
  #100.1 cmd_ready=1;
end

/***************************************************
clock
***************************************************/
always #5 clk=~clk;

endmodule
