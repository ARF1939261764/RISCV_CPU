`include "avl_bus_define.sv"
import avl_bus_type::*;

module avl_bus_1s2n #(
  parameter                    SLAVE_NUM          = 16,
            avl_addr_map_tab_t ADDR_MAP_TAB[31:0] = '{32{'{0,22}}}
)(
  input  logic     clk,
  input  logic     rest
);



endmodule
