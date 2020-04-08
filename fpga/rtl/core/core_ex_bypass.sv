/************************************************************************************************************************************************
旁路单元
*************************************************************************************************************************************************/
module core_ex_bypass(
  input  logic[4:0]  de_rs1,
  input  logic       de_rs1_valid,
  input  logic[4:0]  de_rs2,
  input  logic       de_rs2_valid,
  input  logic[11:0] de_csr,
  input  logic       de_csr_valid,
  input  logic[4:0]  em_rd,
  input  logic       em_reg_write,
  input  logic[11:0] em_csr,
  input  logic       em_csr_write,
  input  logic[4:0]  mw_rd,
  input  logic       mw_reg_write,
  input  logic       mw_mem_data_valid,
  input  logic[11:0] mw_csr,
  input  logic       mw_csr_write,
  output logic[1:0]  rs1_sel,
  output logic[1:0]  rs2_sel,
  output logic[1:0]  csr_sel,
  input  logic       de_start_handle,
  output logic       start_handle
);
logic rs1_em_corl;
logic rs1_mw_corl;
logic rs2_em_corl;
logic rs2_mw_corl;
logic csr_em_corl;
logic csr_mw_corl;
/*冲突判断*/
assign rs1_em_corl  =(de_rs1==em_rd)&&de_rs1_valid&&em_reg_write;
assign rs1_mw_corl  =(de_rs1==mw_rd)&&de_rs1_valid&&mw_reg_write;
assign rs2_em_corl  =(de_rs2==em_rd)&&de_rs2_valid&&em_reg_write;
assign rs2_mw_corl  =(de_rs2==mw_rd)&&de_rs2_valid&&mw_reg_write;
assign csr_em_corl  =(de_csr==em_csr)&&de_csr_valid&&em_csr_write;
assign csr_mw_corl  =(de_csr==mw_csr)&&de_csr_valid&&em_csr_write;
assign start_handle =(rs1_mw_corl|rs2_mw_corl)?mw_mem_data_valid:de_start_handle;
/*rs1 sel*/
always @(*) begin
  if(rs1_em_corl) begin
    rs1_sel=2'd1;
  end
  else if(rs1_mw_corl) begin
    rs1_sel=2'd2;
  end
  else begin
    rs1_sel=2'd0;
  end
end
/*rs2 sel*/
always @(*) begin
  if(rs2_em_corl) begin
    rs2_sel=2'd1;
  end
  else if(rs2_mw_corl) begin
    rs2_sel=2'd2;
  end
  else begin
    rs2_sel=2'd0;
  end
end
/*csr sel*/
always @(*) begin
  if(csr_em_corl) begin
    csr_sel=2'd1;
  end
  else if(csr_mw_corl) begin
    csr_sel=2'd2;
  end
  else begin
    csr_sel=2'd0;
  end
end
endmodule