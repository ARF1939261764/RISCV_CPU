module cpu_biu(
  input logic      clk,
  input logic      rest,
  /*主机接口*/
  i_avl_bus.slave  avl_s_istr,
  i_avl_bus.slave  avl_s_data,
  /*从机接口*/
  /*istr*/
  i_avl_bus.master avl_m_istr_i_cache,
  i_avl_bus.master avl_m_istr_perip,
  i_avl_bus.master avl_m_istr_fast_program_raom,
  i_avl_bus.master avl_m_istr_debug_rom,
  /*data*/
  i_avl_bus.master avl_m_data_d_cache,
  i_avl_bus.master avl_m_data_perip,
  i_avl_bus.master avl_m_data_fast_io,
  i_avl_bus.master avl_m_data_ram_reg
);

/*******************************************************
取指接口到其它接口的地址映射表
*******************************************************/
parameter int AVL_BUS_ISTR_2_OTHER_ADDR_MAP_TAB_FIELD_LEN[0:31]  = '{
              1, 2, 3, 3, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0
            };
parameter int AVL_BUS_ISTR_2_OTHER_ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{
              32'h00000000,32'h80000000,32'hc0000000,32'he0000000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000
            };
/*总线接口*/
i_avl_bus avl_istr_in[0:0]();
i_avl_bus avl_istr_out[3:0]();
/*适配*/
avl_bus_adapter avl_bus_adapter_inst0_istr(.avl_in(avl_s_istr     ),.avl_out(avl_istr_in[0]              ));
avl_bus_adapter avl_bus_adapter_inst1_istr(.avl_in(avl_istr_out[0]),.avl_out(avl_m_istr_i_cache          ));
avl_bus_adapter avl_bus_adapter_inst2_istr(.avl_in(avl_istr_out[1]),.avl_out(avl_m_istr_perip            ));
avl_bus_adapter avl_bus_adapter_inst3_istr(.avl_in(avl_istr_out[2]),.avl_out(avl_m_istr_fast_program_raom));
avl_bus_adapter avl_bus_adapter_inst4_istr(.avl_in(avl_istr_out[3]),.avl_out(avl_m_istr_debug_rom        ));
/*总线控制器*/
avl_bus_n2n #(
  .MASTER_NUM                 (1),
  .SLAVE_NUM                  (4),
  .ARB_METHOD                 (0),
  .BUS_N21_SEL_FIFO_DEPTH     (2),
  .BUS_N21_RES_DATA_FIFO_DEPTH(0),
  .BUS_12N_SEL_FIFO_DEPTH     (2),
  .ADDR_MAP_TAB_FIELD_LEN     (AVL_BUS_ISTR_2_OTHER_ADDR_MAP_TAB_FIELD_LEN),
  .ADDR_MAP_TAB_ADDR_BLOCK    (AVL_BUS_ISTR_2_OTHER_ADDR_MAP_TAB_ADDR_BLOCK)
)
avl_bus_n2n_inst0_istr_2_other(
  .clk       (clk ),
  .rest      (rest),
  .avl_in    (avl_istr_in),
  .avl_out   (avl_istr_out)
);
/*******************************************************
数据接口到其它接口的地址映射表
*******************************************************/
parameter int AVL_BUS_DATA_2_OTHER_ADDR_MAP_TAB_FIELD_LEN[0:31]  = '{
              1, 2, 3, 3, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0
            };
parameter int AVL_BUS_DATA_2_OTHER_ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{
              32'h00000000,32'h80000000,32'hc0000000,32'he0000000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000
            };
/*总线接口*/
i_avl_bus avl_data_in[0:0]();
i_avl_bus avl_data_out[3:0]();
/*适配*/
avl_bus_adapter avl_bus_adapter_inst0_data(.avl_in(avl_s_data     ),.avl_out(avl_data_in[0]     ));
avl_bus_adapter avl_bus_adapter_inst1_data(.avl_in(avl_data_out[0]),.avl_out(avl_m_data_d_cache ));
avl_bus_adapter avl_bus_adapter_inst2_data(.avl_in(avl_data_out[1]),.avl_out(avl_m_data_perip   ));
avl_bus_adapter avl_bus_adapter_inst3_data(.avl_in(avl_data_out[2]),.avl_out(avl_m_data_fast_io ));
avl_bus_adapter avl_bus_adapter_inst4_data(.avl_in(avl_data_out[3]),.avl_out(avl_m_data_ram_reg ));
/*总线控制器*/
avl_bus_n2n #(
  .MASTER_NUM                 (1),
  .SLAVE_NUM                  (4),
  .ARB_METHOD                 (1),
  .BUS_N21_SEL_FIFO_DEPTH     (2),
  .BUS_N21_RES_DATA_FIFO_DEPTH(0),
  .BUS_12N_SEL_FIFO_DEPTH     (2),
  .ADDR_MAP_TAB_FIELD_LEN     (AVL_BUS_DATA_2_OTHER_ADDR_MAP_TAB_FIELD_LEN ),
  .ADDR_MAP_TAB_ADDR_BLOCK    (AVL_BUS_DATA_2_OTHER_ADDR_MAP_TAB_ADDR_BLOCK)
)
avl_bus_n2n_inst0_data_2_other(
  .clk     (clk ),
  .rest    (rest),
  .avl_in  (avl_data_in),
  .avl_out (avl_data_out)
);


endmodule
