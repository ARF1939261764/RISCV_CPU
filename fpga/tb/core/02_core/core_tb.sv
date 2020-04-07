`timescale 1ns/100ps

module core_tb;

logic                  clk;
logic                  rest;
i_avl_bus avl_m0_istr  ();
i_avl_bus avl_m1_data  ();


initial begin
  rest=1;
  #10 rest=0;
  #100 rest=1;
end


core core_inst0(
  .*
);

sdram_sim_model #(
  .SIZE(32*1024),
  .INIT_FILE("../../../../tb/core/file/01_arit_istr_01_bin.txt")
)
sdram_sim_model_inst0_istr(
  .*,
  .avl_m0(avl_m0_istr)
);
sdram_sim_model #(
  .SIZE(32*1024)
)
sdram_sim_model_inst0_data(
  .*,
  .avl_m0(avl_m1_data)
);

always begin
  clk=0;
  forever begin
    #10 clk = ~clk;
  end
end

endmodule
