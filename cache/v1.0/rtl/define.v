`ifndef __DEFINE_V
`define __DEFINE_V

`include "config.v"

`define               cache_io_cmd_wb             (1)
`define               cache_io_cmd_clear          (2)

`define               cache_rw_cmd_nop            (1)
`define               cache_rw_cmd_iorw           (2)
`define               cache_rw_cmd_rb             (3)
`define               cache_rw_handleCtrCmd       (4)

`endif
