`ifndef __CACHE_DEFINE_V
`define __CACHE_DEFINE_V

`include "define.v"

`define CACHE_AVALON_BURST_COUNT_WIDTH          `AVALON_BURST_COUNT_WIDTH

`define cache_io_cmd_wb                         (1)
`define cache_io_cmd_clear                      (2)
      
`define cache_rw_cmd_nop                        (4'd1)
`define cache_rw_cmd_iorw                       (4'd2)
`define cache_rw_cmd_rb                         (4'd3)
`define cache_rw_handleCtrCmd                   (4'd4)
      
`define SIZE_TO_DATA_RAM_ADDR_WIDTH             (log2(SIZE/(32/8*4)))
`define SIZE_TO_TAG_RAM_ADDR_WIDTH              (DATA_RAM_ADDR_WIDTH-4)
`define SIZE_TO_DRE_RAM_ADDR_WIDTH              (log2(SIZE/32)+1)
`define SIZE_TO_TAG_ADDR_WIDTH                  (32-(DATA_RAM_ADDR_WIDTH+2))



`endif