`timescale 1ns/100ps

module core_tb;

logic                  clk;
logic                  rest;
i_avl_bus avl_m0_istr  ();
i_avl_bus avl_m1_data  ();
logic                  csr_read;
logic[11:0]            csr_read_addr;
logic[31:0]            csr_read_data;
logic                  csr_write;
logic[11:0]            csr_write_addr;
logic[31:0]            csr_write_data;

initial begin
  rest=1;
  #10 rest=0;
  #100 rest=1;
end


core core_inst0(
  .*
);

csr_sim_model csr_sim_model_inst0(
  .*
);

sdram_sim_model #(
  .SIZE(32*1024),
  .REQUEST_RANDOM(1'd1),
  .DATA_VALID_RANDOM(1'd1),
  .INIT_FILE("../../../tb/core/file/01_arit_istr_01_bin.txt")
)
sdram_sim_model_inst0_istr(
  .*,
  .avl_m0(avl_m0_istr)
);
sdram_sim_model #(
  .SIZE(32*1024),
  .REQUEST_RANDOM(1'd1),
  .DATA_VALID_RANDOM(1'd0),
  .INIT_FILE("../../../tb/core/file/01_arit_istr_01_bin.txt")
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
