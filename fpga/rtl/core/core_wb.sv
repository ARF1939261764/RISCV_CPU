module core_wb(
  input  logic       clk,
  input  logic       rest,
  /*来自ma*/
  input  logic       mw_valid,
  output logic       mw_ready,
  input  logic[31:0] mw_reg_data,
  input  logic[31:0] mw_mem_data,
  input  logic       mw_mem_data_valid,
  input  logic[31:0] mw_csr_data,
  input  logic[4:0]  mw_rd,
  input  logic       mw_reg_write,
  input  logic       mw_reg_write_sel,
  input  logic[11:0] mw_csr,
  input  logic       mw_csr_write,
  /*去往id*/
  output logic       wb_valid,
  input  logic       wb_ready,
  output logic[31:0] wb_reg_data,
  output logic[4:0]  wb_rd,
  output logic       wb_reg_write,
  output logic[31:0] wb_csr_data,
  output logic[11:0] wb_csr,
  output logic       wb_csr_write
);

assign mw_ready=1'd1;

always @(*) begin
  wb_valid      =mw_valid;
  wb_reg_data   =mw_reg_write_sel?mw_mem_data:mw_reg_data;
  wb_rd         =mw_rd;
  wb_reg_write  =mw_reg_write&&mw_valid;
  wb_csr_data   =mw_csr_data;
  wb_csr        =mw_csr;
  wb_csr_write  =mw_csr_write&&mw_valid;
end
  
endmodule
