`include "core_define.sv"
module core_ex_br(
  input  logic       de_is_br,
  input  logic[3:0]  de_br_op,
  input  logic       de_br_jump,
  input  logic[31:0] rs1_data,
  input  logic[31:0] rs2_data,
  output logic       jump
);

logic jump_en;

always @(*) begin
  case(de_br_op)
    `BR_OP_FALSE:jump_en=1'd0;
    `BR_OP_TRUE :jump_en=1'd1;
    `BR_OP_EQ   :jump_en=rs1_data==rs2_data;
    `BR_OP_NE   :jump_en=rs1_data!=rs2_data;
    `BR_OP_LT   :jump_en=signed'(rs1_data)<signed'(rs2_data);
    `BR_OP_GE   :jump_en=signed'(rs1_data)>=signed'(rs2_data);
    `BR_OP_LIU  :jump_en=unsigned'(rs1_data)<unsigned'(rs2_data);
    `BR_OP_GEU  :jump_en=unsigned'(rs1_data)>=unsigned'(rs2_data);
    default     :jump_en=1'd0;
  endcase
end

assign jump=jump_en&!de_br_jump&de_is_br;
  
endmodule
