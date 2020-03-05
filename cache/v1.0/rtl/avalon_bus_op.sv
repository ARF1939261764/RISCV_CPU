typedef struct
{
  logic[31:0] address;
  logic[3:0]  byteEnable;
  logic       read;
  logic       write;
  logic[31:0] writeData;
  logic       beginBurstTransfer;
  logic[7:0]  burstCount;
}avalon_bus_type;

interface i_avalon_bus;
  logic[31:0] address;
  logic[3:0]  byteEnable;
  logic       read;
  logic       write;
  logic[31:0] writeData;
  logic       beginBurstTransfer;
  logic[7:0]  burstCount;

endinterface






