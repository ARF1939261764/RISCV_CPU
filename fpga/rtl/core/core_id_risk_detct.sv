/************************************************************************************************************************************************
冲突检测
*************************************************************************************************************************************************/
module core_id_risk_detct (
  input  logic[4:0] rs1,
  input  logic      rs1_valid,
  input  logic[4:0] rs2,
  input  logic      rs2_valid,
  input  logic      mem_write,
  input  logic      de_valid,
  input  logic[4:0] de_rd,
  input  logic      de_reg_write,
  input  logic      de_mem_read,
  input  logic      em_valid,
  input  logic[4:0] em_rd,
  input  logic      em_reg_write,
  input  logic      em_mem_read,
  output logic      insert_nop
);
assign insert_nop=(
                    (rs1==de_rd)&&rs1_valid&&de_reg_write&&de_mem_read&&de_valid||
                    (rs2==de_rd)&&rs2_valid&&de_reg_write&&de_mem_read&&de_valid||
                    (rs1==em_rd)&&rs1_valid&&em_reg_write&&em_mem_read&&em_valid||
                    (rs2==em_rd)&&rs2_valid&&em_reg_write&&em_mem_read&&em_valid
                  )&&
                  (
                    !(mem_write&&de_mem_read&&de_reg_write&&(de_rd==rs2)&&de_valid)
                  );
endmodule
