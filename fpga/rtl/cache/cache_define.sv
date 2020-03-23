`ifndef __CACHE_DEFINE_V
`define __CACHE_DEFINE_V

`include "../define/define.sv"

`define CACHE_AVALON_BURST_COUNT_WIDTH          `AVALON_BURST_COUNT_WIDTH

`define cache_ctr_cmd_nop                       (3'd0)
`define cache_ctr_cmd_wb                        (3'd1)
`define cache_ctr_cmd_clear                     (3'd2)
`define cache_ctr_cmd_init                      (3'd3)

`define cache_rw_cmd_nop                        (4'd1)
`define cache_rw_cmd_iorw                       (4'd2)
`define cache_rw_cmd_rb                         (4'd3)
`define cache_rw_handleCtrCmd                   (4'd4)

`endif