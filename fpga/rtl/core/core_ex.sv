module core_ex(
  /*时钟,复位*/
  input  logic       clk,
  input  logic       rest,
  /*ID/EX级寄存器数据*/
  output logic       de_valid,
  output logic       de_wait_handle,
  input  logic       de_ready,
  output logic[3:0]  de_alu_op,
  output logic[31:0] de_rs1_value,
  output logic[31:0] de_csr_value,
  output logic[4:0]  de_zimm,
  output logic[31:0] de_pc,
  output logic[31:0] de_rs2_value,
  output logic[31:0] de_imm,       /*指令中的立即数*/
  output logic[11:0] de_csr,
  output logic[4:0]  de_rd,
  output logic       de_reg_write,
  output logic       de_csr_write,
  output logic       de_mem_write,
  output logic       de_mem_read,
  output logic       de_mem_op,
  output logic       de_istr_width,
  output logic       de_is_br,      /*是否为分支指令*/
  output logic[3:0]  de_br_op,      /*分支需要进行的比较操作:等于?，不等于?,或者恒为真/假*/
  output logic       de_jump,       /*这条指令是否在前面已经跳转了*/
  output logic[4:0]  de_rs1,
  output logic[4:0]  de_rs2,
  output logic       de_rs1_valid,
  output logic       de_rs2_valid,
  output logic[1:0]  de_alu_port_1_sel,
  output logic[1:0]  de_alu_port_2_sel,
  output logic[1:0]  de_em_reg_data_addr_sel,
  output logic[1:0]  de_em_csr_data_sel,
  /*EX/MEM级寄存器数据*/
  output logic       em_valid,
  output logic       em_wait_handle,
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
/*alu 端口*/
logic[4:0]  alu_op;
logic       alu_op_valid;
logic       alu_op_ready;
logic[31:0] alu_in1;
logic[31:0] alu_in2;
logic[31:0] alu_out;

logic[1:0]  alu_in1_sel;
logic[1:0]  alu_in2_sel;

logic[31:0] rs1_value;
logic[1:0]  rs1_sel;
logic[31:0] rs2_value;
logic[1:0]  rs2_sel;

logic[31:0] csr_value;

  

/**************************************************************
连线
**************************************************************/
assign alu_op         = de_alu_op;
assign alu_op_valid   = de_valid;




/**************************************************************
模块实例化
**************************************************************/
/*alu*/
core_ex_alu core_ex_alu_inst0(
  .clk             (clk          ),
  .rest            (rest         ),
  .op              (alu_op       ),
  .op_wait_handle  (alu_op_valid ),
  .op_ready        (alu_op_ready ),
  .in1             (alu_in1      ),
  .in2             (alu_in2      ),
  .out             (alu_out      )
);

endmodule


