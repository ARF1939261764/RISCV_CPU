`include "cache_define.sv"

module cache_arb(
  input  logic                                        clk,
  input  logic                                        rest,
  /*s0从机接口:接到cache顶层模块的从机接口,供cpu访问*/
  input  logic [31:0]                                 s0_address,
  input  logic [3:0]                                  s0_byteEnable,
  input  logic                                        s0_read,
  input  logic                                        s0_write,
  input  logic [31:0]                                 s0_writeData,
  output logic                                        s0_waitRequest,
  output logic [31:0]                                 s0_readData,
  output logic                                        s0_readDataValid,
  /*s1从机接口:接到cache_ri模块,供替换模块(rw module)访问总线使用*/
  input  logic [31:0]                                 s1_address,
  input  logic [3:0]                                  s1_byteEnable,
  input  logic                                        s1_read,
  input  logic                                        s1_write,
  input  logic [31:0]                                 s1_writeData,
  output logic                                        s1_waitRequest,
  input  logic                                        s1_beginBurstTransfer,
  input  logic [`CACHE_AVALON_BURST_COUNT_WIDTH-1:0]  s1_burstCount,
  output logic [31:0]                                 s1_readData,
  output logic                                        s1_readDataValid,
  /*m0主机接口:接到cache_rw模块,访问cache模块*/
  output logic [31:0]                                 m0_address,
  output logic [3:0]                                  m0_byteEnable,
  output logic                                        m0_read,
  output logic                                        m0_write,
  output logic [31:0]                                 m0_writeData,
  input  logic                                        m0_waitRequest,
  input  logic [31:0]                                 m0_readData,
  input  logic                                        m0_readDataValid,
  /*接到cache_rw模块*/
  output                                              rw_bus_idle,
  input                                               rw_cache_is_enable,
  /*m1主机接口:接到总线*/
  output logic [31:0]                                 m1_address,
  output logic [3:0]                                  m1_byteEnable,
  output logic                                        m1_read,
  output logic                                        m1_write,
  output logic [31:0]                                 m1_writeData,
  input  logic                                        m1_waitRequest,
  output logic                                        m1_beginBurstTransfer,
  output logic [`CACHE_AVALON_BURST_COUNT_WIDTH-1:0]  m1_burstCount,
  input  logic [31:0]                                 m1_readData,
  input  logic                                        m1_readDataValid
);

reg[3:0] count;
wire sel;
wire is_io_addr;
wire m0_cmd_mask;
wire m1_rsp_mask;

assign is_io_addr=s0_address[31];
assign rw_bus_idle=(count==0)?1'd1:1'd0;
assign sel=(m0_waitRequest||(!is_io_addr))&&(count==0)&&rw_cache_is_enable;/*1:选择左,0:IO*/
assign m0_cmd_mask=sel;
assign m1_rsp_mask=sel;

/*****************************************************************************************************************
命令mux
*****************************************************************************************************************/
assign {
  m0_address,
  m0_byteEnable,
  m0_read,
  m0_write,
  m0_writeData
}=
{
  s0_address,
  s0_byteEnable,
  s0_read&&m0_cmd_mask,
  s0_write&&m0_cmd_mask,
  s0_writeData
};
/*****************************************************************************************************************
命令mux
*****************************************************************************************************************/
assign {
  m1_address,
  m1_byteEnable,
  m1_read,
  m1_write,
  m1_writeData,
  m1_beginBurstTransfer,
  m1_burstCount
}=sel?
{
  s1_address,
  s1_byteEnable,
  s1_read,
  s1_write,
  s1_writeData,
  s1_beginBurstTransfer,
  s1_burstCount
}:
{
  s0_address,
  s0_byteEnable,
  s0_read,
  s0_write,
  s0_writeData,
  1'd0,
  {`CACHE_AVALON_BURST_COUNT_WIDTH{1'd0}}
};
assign s1_waitRequest=m1_waitRequest;
assign s0_waitRequest=!m0_waitRequest;
/*****************************************************************************************************************
响应
*****************************************************************************************************************/
assign {
  s0_readData,
  s0_readDataValid
}=sel?
{
  m0_readData,
  m0_readDataValid
}:
{
  m1_readData,
  m1_readDataValid
};
assign {
  s1_readData,
  s1_readDataValid
}=
{
  m1_readData,
  m1_readDataValid&&m1_rsp_mask
};
/*****************************************************************************************************************
IO读写时计数
*****************************************************************************************************************/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    count<=0;
  end
  else begin
    case({sel,!m1_waitRequest&&m1_read,m1_readDataValid})
      3'b001:count<=(count>4'd0)?count-4'd1:count;
      3'b010:count<=(count<4'd15)?count+4'd1:count;
      default:begin end
    endcase
  end
end

endmodule
