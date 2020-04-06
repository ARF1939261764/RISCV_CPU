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
  input  logic[1:0]  em_mem_op_type,
  input  logic[4:0]  em_rd,
  input  logic       em_reg_write,
  input  logic[11:0] em_csr,
  input  logic       em_csr_write,
  /*去往wb*/
  output logic       mw_valid,
  input  logic       mw_ready,
  output logic[31:0] mw_reg_data,
  output logic[31:0] mw_mem_data,
  output logic       mw_mem_data_valid,
  output logic[31:0] mw_csr_data,
  output logic[4:0]  mw_rd,
  output logic       mw_reg_write,
  output logic       mw_reg_write_sel,
  output logic[11:0] mw_csr,
  output logic       mw_csr_write,
  /*mem访问接口*/
  i_avl_bus.master  avl_m0
);

always @(posedge clk or negedge rest) begin
  if(!rest) begin
    mw_valid          = 1'd0;
    mw_reg_data       = 1'd0;
    mw_mem_data       = 1'd0;
    mw_mem_data_valid = 1'd0;
    mw_csr_data       = 1'd0;
    mw_rd             = 1'd0;
    mw_reg_write      = 1'd0;
    mw_reg_write_sel  = 1'd0;
    mw_csr            = 1'd0;
    mw_csr_write      = 1'd0;
  end
  else begin
    mw_valid          = em_valid;
    mw_reg_data       = em_reg_data_mem_addr;
    mw_mem_data       = avl_m0.read_data;
    mw_mem_data_valid = avl_m0.read_data_valid;
    mw_csr_data       = em_csr_data_mem_data;
    mw_rd             = em_rd;
    mw_reg_write      = em_reg_write;
    mw_reg_write_sel  = em_mem_read?1'd1:1'd0;
    mw_csr            = em_csr;
    mw_csr_write      = em_csr_write;

  end
end

assign em_ready=1'd1;

assign avl_m0.address=em_reg_data_mem_addr;
assign avl_m0.byte_en=4'hf;
assign avl_m0.read=em_mem_read;
assign avl_m0.write=em_mem_write;
assign avl_m0.write_data=em_csr_data_mem_data;
assign avl_m0.begin_burst_transfer=1'd0;
assign avl_m0.burst_count=1'd0;

endmodule