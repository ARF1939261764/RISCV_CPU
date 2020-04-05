module core_ex(
  /*时钟,复位*/
  input  logic       clk,
  input  logic       rest,
  /*ID/EX级寄存器数据*/
  input  logic       de_valid,
  input  logic       de_start_handle,
  output logic       de_ready,
  input  logic[3:0]  de_alu_op,
  input  logic[31:0] de_rs1_value,
  input  logic[31:0] de_csr_value,
  input  logic[4:0]  de_zimm,
  input  logic[31:0] de_pc,
  input  logic[31:0] de_rs2_value,
  input  logic[31:0] de_imm,       /*指令中的立即数*/
  input  logic[4:0]  de_rd,
  input  logic       de_reg_write,
  input  logic       de_csr_write,
  input  logic       de_mem_write,
  input  logic       de_mem_read,
  input  logic       de_mem_op,
  input  logic       de_istr_width,
  input  logic       de_is_br,      /*是否为分支指令*/
  input  logic[3:0]  de_br_op,      /*分支需要进行的比较操作:等于?，不等于?,或者恒为真/假*/
  input  logic       de_jump,       /*这条指令是否在前面已经跳转了*/
  input  logic[11:0] de_csr,
  input  logic       de_csr_valid,
  input  logic[4:0]  de_rs1,
  input  logic[4:0]  de_rs2,
  input  logic       de_rs1_valid,
  input  logic       de_rs2_valid,
  input  logic[1:0]  de_alu_in_1_sel,
  input  logic[1:0]  de_alu_in_2_sel,
  input  logic[1:0]  de_em_reg_data_addr_sel,
  input  logic[1:0]  de_em_csr_data_sel,
  /*EX/MEM级寄存器数据*/
  output logic       em_valid,
  output logic       em_start_handle,
  input  logic       em_ready,
  output logic[31:0] em_reg_data_mem_addr,
  output logic[31:0] em_csr_data_mem_data,
  output logic       em_mem_read,
  output logic       em_mem_write,
  output logic       em_mem_op_type,
  output logic       em_rd,
  output logic       em_reg_write,
  output logic       em_reg_write_sel,
  output logic[11:0] em_csr,
  output logic       em_csr_write,
  /*mw*/
  input  logic[31:0] mw_reg_write_data,
  input  logic[31:0] mw_csr_data;
  /*异常/中断接口*/
  input  logic       exception_valid,
  input  logic       exception_ready,
  input  logic[31:0] exception_cause,/*异常/中断原因,最高位表示当前异常是狭义上的异常还是中断*/
  input  logic[31:0] exception_csr_mtvec,
  /*输出到csr module*/
  output logic[31:0] pc,
  output logic[31:0] next_pc,
  output logic[31:0] istr,
  /*取指/译码级，跳转、冲刷流水控制*/
  output logic       jump_en,
  output logic[31:0] jump_addr,
  output logic       flush_en,
  /*给到分支预测器*/
  output logic[31:0] bp_pc,
  output logic[31:0] bp_istr,
  output logic[31:0] bp_jump_pc,
  output logic       bp_jump_en,
  output logic       bp_is_exception
);
/**************************************************************
变量
**************************************************************/
logic[4:0]  alu_op;
logic       alu_op_valid;
logic       alu_op_ready;
logic[31:0] alu_out;
logic[31:0] alu_in1;
logic[31:0] alu_in2;
logic[1:0]  alu_in1_sel;
logic[1:0]  alu_in2_sel;
logic[31:0] rs1_value;
logic[1:0]  rs1_sel;
logic[31:0] rs2_value;
logic[1:0]  rs2_sel;
logic[31:0] csr_value;
logic[1:0]  csr_sel;
logic[31:0] csr_data_mem_data;
logic[1:0]  csr_data_mem_data_sel;
logic[31:0] reg_data_mem_addr;
logic[1:0]  reg_data_mem_addr_sel;
logic       start_handle;
logic[31:0] pc_add_2;
logic[31:0] pc_add_4;
logic       pc_add;
/**************************************************************
选择rs1,rs2,csr的数据源
**************************************************************/
always @(*) begin
  case(rs1_sel)
    2'd0:rs1_value=de_rs1_value;
    2'd1:rs1_value=em_reg_data_mem_addr;
    2'd2:rs1_value=mw_reg_write_data;
    default:rs1_value=de_rs1_value;
  endcase
  case(rs2_sel)
    2'd0:rs2_value=de_rs1_value;
    2'd1:rs2_value=em_reg_data_mem_addr;
    2'd2:rs2_value=mw_reg_write_data;
    default:rs2_value=de_rs1_value;
  endcase
  case(csr_sel)
    2'd0:csr_value=de_csr_value;
    2'd1:csr_value=em_csr_data_mem_data;
    2'd2:csr_value=mw_csr_data;
    default:csr_value=de_csr_value;
  endcase
end

always @(*) begin
  case(reg_data_mem_addr_sel)
    2'd0:reg_data_mem_addr=alu_out;
    2'd1:reg_data_mem_addr=de_imm;
    2'd2:reg_data_mem_addr=csr_value;
    2'd3:reg_data_mem_addr=pc_add;
    default:reg_data_mem_addr=alu_out;
  endcase
end

always @(*) begin
  case(csr_data_mem_data_sel)
    2'd0:csr_data_mem_data=alu_out;
    2'd1:csr_data_mem_data=rs1_value;
    default:csr_data_mem_data=alu_out;
    default:
  endcase
end

/**************************************************************
选择alu_in1,alu_in2的数据源
**************************************************************/
always @(*) begin
  case(de_alu_in_1_sel) begin
    2'd0:alu_in1=rs1_value;
    2'd1:alu_in1=de_zimm;
    2'd2:alu_in1=de_pc;
    default:alu_in1=rs1_value;
  end
  case(de_alu_in_2_sel) begin
    2'd0:alu_in2=rs2_value;
    2'd1:alu_in2=de_csr_value;
    2'd2:alu_in2=de_imm;
    default:alu_in2=rs2_value;
  end
end

/**************************************************************
连线
**************************************************************/
assign alu_op        = de_alu_op;
assign alu_op_valid  = de_valid;

/*************************************************************
更新em寄存器
*************************************************************/

/**************************************************************
模块实例化
**************************************************************/
/*alu*/
core_ex_alu core_ex_alu_inst0(
  .clk                    (clk                    ),
  .rest                   (rest                   ),
  .op                     (alu_op                 ),
  .op_wait_handle         (alu_op_valid           ),
  .op_ready               (alu_op_ready           ),
  .in1                    (alu_in1                ),
  .in2                    (alu_in2                ),
  .out                    (alu_out                )
);
/*旁路单元*/
core_ex_bypass core_ex_bypass_inst0(
  .de_rs1                 (de_rs1_value           ),
  .de_rs1_valid           (de_rs1_valid           ),
  .de_rs2                 (de_rs2_value           ),
  .de_rs2_valid           (de_rs2_valid           ),
  .de_csr                 (de_csr                 ),
  .de_csr_valid           (de_csr_valid           ),
  .em_rd                  (em_rd                  ),
  .em_reg_write           (em_reg_write           ),
  .em_csr                 (em_csr                 ),
  .em_csr_write           (em_csr_write           ),
  .mw_rd                  (mw_rd                  ),
  .mw_reg_write           (mw_reg_write           ),
  .mw_mem_read_data_valid (mw_mem_read_data_valid),
  .mw_csr                 (mw_csr                 ),
  .mw_csr_write           (mw_csr_write           ),
  .rs1_sel                (rs1_sel                ),
  .rs2_sel                (rs2_sel                ),
  .csr_sel                (csr_sel                ),
  .de_start_handle        (de_start_handle        ),
  .start_handle           (start_handle           )
);

endmodule
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
  input  logic       mw_mem_read_data_valid,
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
assign start_handle =(rs1_mw_corl|rs2_mw_corl)?mw_mem_read_data_valid:de_start_handle;
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
