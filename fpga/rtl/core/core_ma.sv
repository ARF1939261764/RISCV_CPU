module core_ma(
  input  logic       clk,
  input  logic       rest,
  /*来自ex*/
  input  logic       em_valid,
  input  logic       em_start_handle,
  output logic       em_ready,
  input  logic[31:0] em_reg_data_mem_addr,
  input  logic[31:0] em_csr_data_mem_data,
  input  logic       em_mem_read,
  input  logic       em_mem_write,
  input  logic       em_mem_op_type,
  input  logic       em_rd,
  input  logic       em_reg_write,
  output logic       em_reg_write_sel,
  input  logic[11:0] em_csr,
  input  logic       em_csr_write,
  /*去往wb*/
  output logic       mw_valid,
  input  logic       mw_ready,
  output logic[31:0] mw_reg_data,
  output logic[31:0] mw_mem_data,
  output logic[31:0] mw_csr_data,
  output logic[4:0]  mw_rd,
  output logic       mw_reg_write,
  output logic       mw_reg_write_sel,
  output logic[11:0] mw_csr,
  output logic       mw_csr_write,
  /*mem访问接口*/
  i_avl_bus.master  avl_m0
);

endmodule