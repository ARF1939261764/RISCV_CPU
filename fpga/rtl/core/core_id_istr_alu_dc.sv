`include "core_define.sv"

import core_type::*;

module core_id_istr_alu_dc(
  input  istr_dc_info_t     istr_dc_info,
  output istr_alu_dc_info_t istr_alu_dc_info
);

/*ALU操作码选择信号*/
logic       alu_op_is_add;
logic       alu_op_is_sub;
logic       alu_op_is_sll;
logic       alu_op_is_slt;
logic       alu_op_is_sltu;
logic       alu_op_is_xor;
logic       alu_op_is_srl;
logic       alu_op_is_sra;
logic       alu_op_is_or;
logic       alu_op_is_and;
logic       alu_op_is_not_and;
assign      alu_op_is_add     = istr_dc_info.istr_is_ra_add      ||istr_dc_info.istr_is_ia_addi||
                                istr_dc_info.istr_is_ld          ||istr_dc_info.istr_is_sd     ||
                                istr_dc_info.istr_is_br          ||istr_dc_info.istr_is_jr     ||
                                istr_dc_info.istr_is_j           ||istr_dc_info.istr_is_auipc;
assign      alu_op_is_sub     = istr_dc_info.istr_is_ra_sub;
assign      alu_op_is_sll     = istr_dc_info.istr_is_ra_sll      ||istr_dc_info.istr_is_ia_slli;
assign      alu_op_is_slt     = istr_dc_info.istr_is_ra_slt      ||istr_dc_info.istr_is_ia_slti;
assign      alu_op_is_sltu    = istr_dc_info.istr_is_ra_sltu     ||istr_dc_info.istr_is_ia_sltiu;
assign      alu_op_is_xor     = istr_dc_info.istr_is_ra_xor      ||istr_dc_info.istr_is_ia_xori;
assign      alu_op_is_srl     = istr_dc_info.istr_is_ra_srl      ||istr_dc_info.istr_is_ia_srli;
assign      alu_op_is_sra     = istr_dc_info.istr_is_ra_sra      ||istr_dc_info.istr_is_ia_srai;
assign      alu_op_is_or      = istr_dc_info.istr_is_ra_or       ||istr_dc_info.istr_is_ia_ori ||
                                istr_dc_info.istr_is_sys_csrrs   ||istr_dc_info.istr_is_sys_csrrsi;
assign      alu_op_is_and     = istr_dc_info.istr_is_ra_and      ||istr_dc_info.istr_is_ia_andi;
assign      alu_op_is_not_and = istr_dc_info.istr_is_sys_csrrc   ||istr_dc_info.istr_is_sys_csrrci;

/*得出de寄存器组的值*/
assign      istr_alu_dc_info.alu_op            =  {4{alu_op_is_add    }}&`ALU_OP_ADD  |
                                                  {4{alu_op_is_sub    }}&`ALU_OP_SUB  |
                                                  {4{alu_op_is_sll    }}&`ALU_OP_SLL  |
                                                  {4{alu_op_is_slt    }}&`ALU_OP_SLT  |
                                                  {4{alu_op_is_sltu   }}&`ALU_OP_SLTU |
                                                  {4{alu_op_is_xor    }}&`ALU_OP_XOR  |
                                                  {4{alu_op_is_srl    }}&`ALU_OP_SRL  |
                                                  {4{alu_op_is_sra    }}&`ALU_OP_SRA  |
                                                  {4{alu_op_is_or     }}&`ALU_OP_OR   |
                                                  {4{alu_op_is_and    }}&`ALU_OP_AND  |
                                                  {4{alu_op_is_not_and}}&`ALU_OP_NOT_AND;

endmodule