module core_wb(
  input  logic       clk,
  input  logic       rest,
  /*来自ma*/
  input  logic       mw_valid,
  output logic       mw_ready,
  input  logic[31:0] mw_reg_data,
  input  logic[31:0] mw_mem_data,
  input  logic[31:0] mw_csr_data,
  input  logic[4:0]  mw_rd,
  input  logic       mw_reg_write,
  input  logic       mw_reg_write_sel,
  input  logic[11:0] mw_csr,
  input  logic       mw_csr_write,
  /*去往id*/
  output logic       wd_valid,
  input  logic       wd_ready,
  output logic[31:0] wd_reg_data,
  output logic[4:0]  wd_rd,
  output logic       wd_reg_write,
  output logic[31:0] wd_csr_data,
  output logic[11:0] wd_csr,
  output logic       wd_csr_write
);
  
endmodule
