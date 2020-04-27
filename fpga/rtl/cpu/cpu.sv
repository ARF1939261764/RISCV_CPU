module cpu (
  input logic      clk,
  input logic      rest,
  i_avl_bus.master avl_m_mem_bus_0,
  i_avl_bus.master avl_m_mem_bus_1,
  i_avl_bus.master avl_m_per_bus_0,
  i_avl_bus.master avl_m_per_bus_1
);

core(
  .clk            (),
  .rest           (),
  .csr_read       (),
  .csr_read_addr  (),
  .csr_read_data  (),
  .csr_write      (),
  .csr_write_addr (),
  .csr_write_data (),
  .avl_m0_istr    (),
  .avl_m1_data    ()
);

cache #(
	.SIZE      (8*1024),
  .BLOCK_SIZE(64    )
)
cache_inst0_istr(
	.clk            (),
	.rest           (),
  .avl_s0         (),
  .avl_s1         (),
  .avl_m0         () 
);

cache #(
	.SIZE      (8*1024),
  .BLOCK_SIZE(64    )
)
cache_inst0_data(
	.clk            (),
	.rest           (),
  .avl_s0         (),
  .avl_s1         (),
  .avl_m0         () 
);

cpu_biu cpu_biu_inst0(
  .clk                          (),
  .rest                         (),
  .avl_s_istr                   (),
  .avl_s_data                   (),
  .avl_m_istr_i_cache           (),
  .avl_m_istr_perip             (),
  .avl_m_istr_fast_program_raom (),
  .avl_m_istr_debug_rom         (),
  .avl_m_data_d_cache           (),
  .avl_m_data_perip             (),
  .avl_m_data_fast_io           (),
  .avl_m_data_ram_reg           ()
);

endmodule