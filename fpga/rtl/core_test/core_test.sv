module core_test (
  input  logic clk,
  input  logic rest,
  inout  wire  io[31:0]
);

i_avl_bus avl_bus_istr();
i_avl_bus avl_bus_data();

i_avl_bus avl_bus_data_bus_in[0:0]();
i_avl_bus avl_bus_data_bus_out[1:0]();

logic pll_c0;
logic pll_c1;


PLL  pll_inst0(
  .inclk0(clk),
	.c0    (pll_c0),
  .c1    (pll_c1)
);

core core_inst0(
  .clk            (pll_c0),
  .rest           (rest),
  .avl_m0_istr    (avl_bus_istr),
  .avl_m1_data    (avl_bus_data),
  .csr_read       (),
  .csr_read_addr  (),
  .csr_read_data  (),
  .csr_write      (),
  .csr_write_addr (),
  .csr_write_data ()
);

avl_dual_port_ram #(
  .DEPTH          (64*1024/4 )
)avl_dual_port_ram_inst0(
  .clk   (pll_c0),
  .rest  (rest),
  .avl_s0(avl_bus_data_bus_out[0]),
  .avl_s1(avl_bus_istr)
);

gpio gpio_inst0(
  .clk    (pll_c0),
  .rest   (rest  ),
  .avl_s0 (avl_bus_data_bus_out[1]),
  .io     (io)
);

localparam int AVL_BUS_DATA_BUS_ADDR_MAP_TAB_FIELD_LEN[0:31]  = '{
              16,17,0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0
            };
localparam int AVL_BUS_DATA_BUS_ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{
              32'h00000000,32'h00010000,32'h00010000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,
              32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,
              32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,
              32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000,32'h00000000
            };

avl_bus_adapter avl_bus_adapter_data_bus_inst0(.avl_in(avl_bus_data),.avl_out(avl_bus_data_bus_in[0]));

avl_bus_n2n #(
  .MASTER_NUM                    (1),
  .SLAVE_NUM                     (2),
  .ARB_METHOD                    (0),
  .BUS_N21_SEL_FIFO_DEPTH        (2),
  .BUS_N21_RES_DATA_FIFO_DEPTH   (0),
  .BUS_12N_SEL_FIFO_DEPTH        (2),
  .ADDR_MAP_TAB_FIELD_LEN        (AVL_BUS_DATA_BUS_ADDR_MAP_TAB_FIELD_LEN),
  .ADDR_MAP_TAB_ADDR_BLOCK       (AVL_BUS_DATA_BUS_ADDR_MAP_TAB_ADDR_BLOCK)
)
avl_bus_n2n_inst0(
  .clk    (pll_c0),
  .rest   (rest),
  .avl_in (avl_bus_data_bus_in),
  .avl_out(avl_bus_data_bus_out)
);

endmodule