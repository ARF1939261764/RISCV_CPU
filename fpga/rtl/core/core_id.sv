module core_id(
  input   logic         clk,
  input   logic         rest,
  /*来自取指阶段的信号*/
  input   logic[31:0]   if_istr,
  input   logic[31:0]   if_pc,
  input   logic         if_valid,
  input   logic         if_jump,
  output  logic         if_ready
  /*来自ex级的信号*/
  input  logic          flush_en,
  /*给到下一级*/
  output logic          de_valid,
  input  logic          de_ready,
  output logic[3:0]     de_alu_op,
  output logic[31:0]    de_rs1_value,
  output logic[31:0]    de_rs2_value,
  output logic[12:0]    de_sb_imm,     /*SB类型指令中的立即数*/
  output logic[31:0]    de_pc,
  output logic[4:0]     de_rd,
  output logic[11:0]    de_csr,
  output logic          de_reg_write,
  output logic          de_csr_write,
  output logic          de_mem_write,
  output logic          de_mem_read,
  output logic          de_mem_op_type,
  output logic          de_istr_width,
  output logic          de_is_br,      /*是否为分支指令*/
  output logic[3:0]     de_br_op,      /*分支需要进行的比较操作:等于?，不等于?,或者恒为真/假*/
  output logic          de_jump,       /*这条指令是否在前面已经跳转了*/

);
/****************************************************************************************
function
****************************************************************************************/
/*从指令中获取rd*/
function logic [4:0] istr_get_rd(logic[31:0] istr);
  return istr[11:7];
endfunction
/*从指令中获取rs1*/
function logic [4:0] istr_get_rs1(logic[31:0] istr);
  return istr[19:15];
endfunction
/*从指令中获取rs2*/
function logic [4:0] istr_get_rs2(logic[31:0] istr);
  return istr[24:20];
endfunction
/*获取opcode*/
function logic [6:0] istr_get_opcode(logic[31:0] istr);
  return istr[6:0];
endfunction
/*获取funct3*/
function logic [2:0] istr_get_funct3(logic[31:0] istr);
  return istr[14:12];
endfunction
/*获取funct7*/
function logic [6:0] istr_get_funct7(logic[31:0] istr);
  return istr[31:25];  
endfunction
/*获取I类型指令的立即数*/
function logic[11:0] istr_i_get_imm(logic[31:0] istr);
  return istr[31:20];
endfunction
/*获取S类型指令的立即数*/
function logic[11:0] istr_s_get_imm(logic[31:0] istr);
  return {istr[31:25],istr[11:7]};
endfunction
/*获取SB类型指令的立即数*/
function logic[12:0] istr_sb_get_imm(logic[31:0] istr);
  return {istr[31],istr[7],istr[30:25],istr[11:6]};
endfunction
/*获取U类型指令的立即数*/
function logic[31:0] istr_u_get_imm(logic[31:0] istr);
  return {istr[31:12],12'd0};
endfunction
/*获取UI类型指令的立即数*/
function logic[20:0] istr_ui_get_imm(logic[31:0] istr);
  return {istr[31],istr[19:12],istr[20],istr[30:21],1'b0};
endfunction


/****************************************************************************************
变量
****************************************************************************************/
logic        reg_file_clk;
logic[4:0]   reg_file_read_0_addr;
logic[31:0]  reg_file_read_0_data;
logic[4:0]   reg_file_read_1_addr;
logic[31:0]  reg_file_read_1_data;
logic[4:0]   reg_file_write_addr;
logic[31:0]  reg_file_write_data;
logic        reg_file_write_en;

/****************************************************************************************
连线
****************************************************************************************/

/****************************************************************************************
module实例化
****************************************************************************************/
/*寄存器文件*/
core_id_reg_file core_id_reg_file_inst0(
  .clk          (clk                   ),
  .read_0_addr  (reg_file_read_0_addr  ),
  .read_0_data  (reg_file_read_0_data  ),
  .read_1_addr  (reg_file_read_1_addr  ),
  .read_1_data  (reg_file_read_1_data  ),
  .write_addr   (reg_file_write_addr   ),
  .write_data   (reg_file_write_data   ),
  .write_en     (reg_file_write_en     )
);

endmodule
