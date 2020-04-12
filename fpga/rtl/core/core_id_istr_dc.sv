`include "core_define.sv"

import core_type::*;

module core_id_istr_dc(
  input  logic[31:0]    istr,
  output istr_dc_info_t istr_dc_info
);
logic[4:0]   istr_opcode;
logic[2:0]   istr_funct3;
logic[6:0]   istr_funct7;

assign istr_opcode       = istr[6:2];
assign istr_funct3       = istr[14:12];
assign istr_funct7       = istr[31:25];

/*opcode decode*/
assign istr_dc_info.istr_is_ra        = istr_opcode==`ISTR_RA;
assign istr_dc_info.istr_is_ia        = istr_opcode==`ISTR_IA;
assign istr_dc_info.istr_is_ld        = istr_opcode==`ISTR_LD;
assign istr_dc_info.istr_is_sd        = istr_opcode==`ISTR_SD;
assign istr_dc_info.istr_is_br        = istr_opcode==`ISTR_BR;
assign istr_dc_info.istr_is_jr        = istr_opcode==`ISTR_JR;
assign istr_dc_info.istr_is_j         = istr_opcode==`ISTR_J;
assign istr_dc_info.istr_is_lui       = istr_opcode==`ISTR_LUI;
assign istr_dc_info.istr_is_auipc     = istr_opcode==`ISTR_AUIPC;
assign istr_dc_info.istr_is_fence     = istr_opcode==`ISTR_FENCE;
assign istr_dc_info.istr_is_sys       = istr_opcode==`ISTR_SYS;
/*ra系*/
assign istr_dc_info.istr_is_ra_add    = istr_dc_info.istr_is_ra&&((istr_funct3==`ISTR_RA_ADD_FUNCT3   )&&(istr_funct7==`ISTR_RA_ADD_FUNCT7   ));
assign istr_dc_info.istr_is_ra_sub    = istr_dc_info.istr_is_ra&&((istr_funct3==`ISTR_RA_SUB_FUNCT3   )&&(istr_funct7==`ISTR_RA_SUB_FUNCT7   ));
assign istr_dc_info.istr_is_ra_sll    = istr_dc_info.istr_is_ra&&((istr_funct3==`ISTR_RA_SLL_FUNCT3   )&&(istr_funct7==`ISTR_RA_SLL_FUNCT7   ));
assign istr_dc_info.istr_is_ra_slt    = istr_dc_info.istr_is_ra&&((istr_funct3==`ISTR_RA_SLT_FUNCT3   )&&(istr_funct7==`ISTR_RA_SLT_FUNCT7   ));
assign istr_dc_info.istr_is_ra_sltu   = istr_dc_info.istr_is_ra&&((istr_funct3==`ISTR_RA_SLTU_FUNCT3  )&&(istr_funct7==`ISTR_RA_SLTU_FUNCT7  ));
assign istr_dc_info.istr_is_ra_xor    = istr_dc_info.istr_is_ra&&((istr_funct3==`ISTR_RA_XOR_FUNCT3   )&&(istr_funct7==`ISTR_RA_XOR_FUNCT7   ));
assign istr_dc_info.istr_is_ra_srl    = istr_dc_info.istr_is_ra&&((istr_funct3==`ISTR_RA_SRL_FUNCT3   )&&(istr_funct7==`ISTR_RA_SRL_FUNCT7   ));
assign istr_dc_info.istr_is_ra_sra    = istr_dc_info.istr_is_ra&&((istr_funct3==`ISTR_RA_SRA_FUNCT3   )&&(istr_funct7==`ISTR_RA_SRA_FUNCT7   ));
assign istr_dc_info.istr_is_ra_or     = istr_dc_info.istr_is_ra&&((istr_funct3==`ISTR_RA_OR_FUNCT3    )&&(istr_funct7==`ISTR_RA_OR_FUNCT7    ));
assign istr_dc_info.istr_is_ra_and    = istr_dc_info.istr_is_ra&&((istr_funct3==`ISTR_RA_AND_FUNCT3   )&&(istr_funct7==`ISTR_RA_AND_FUNCT7   ));
/*ia系*/
assign istr_dc_info.istr_is_ia_addi   = istr_dc_info.istr_is_ia&&((istr_funct3==`ISTR_IA_ADDI_FUNCT3  ));
assign istr_dc_info.istr_is_ia_slti   = istr_dc_info.istr_is_ia&&((istr_funct3==`ISTR_IA_SLTI_FUNCT3  ));
assign istr_dc_info.istr_is_ia_sltiu  = istr_dc_info.istr_is_ia&&((istr_funct3==`ISTR_IA_SLTIU_FUNCT3 ));
assign istr_dc_info.istr_is_ia_xori   = istr_dc_info.istr_is_ia&&((istr_funct3==`ISTR_IA_XORI_FUNCT3  ));
assign istr_dc_info.istr_is_ia_ori    = istr_dc_info.istr_is_ia&&((istr_funct3==`ISTR_IA_ORI_FUNCT3   ));
assign istr_dc_info.istr_is_ia_andi   = istr_dc_info.istr_is_ia&&((istr_funct3==`ISTR_IA_ANDI_FUNCT3  ));
assign istr_dc_info.istr_is_ia_slli   = istr_dc_info.istr_is_ia&&((istr_funct3==`ISTR_RA_SLLI_FUNCT3  ));
assign istr_dc_info.istr_is_ia_srli   = istr_dc_info.istr_is_ia&&((istr_funct3==`ISTR_IA_SRLI_FUNCT3  ));
assign istr_dc_info.istr_is_ia_srai   = istr_dc_info.istr_is_ia&&((istr_funct3==`ISTR_IA_SRAI_FUNCT3  ));
/*ld系*/
assign istr_dc_info.istr_is_ld_lb     = istr_dc_info.istr_is_ld&&(istr_funct3==`ISTR_LD_LB_FUNCT3     );
assign istr_dc_info.istr_is_ld_lh     = istr_dc_info.istr_is_ld&&(istr_funct3==`ISTR_LD_LH_FUNCT3     );
assign istr_dc_info.istr_is_ld_lw     = istr_dc_info.istr_is_ld&&(istr_funct3==`ISTR_LD_LW_FUNCT3     );
assign istr_dc_info.istr_is_ld_lbu    = istr_dc_info.istr_is_ld&&(istr_funct3==`ISTR_LD_LBU_FUNCT3    );
assign istr_dc_info.istr_is_ld_lhu    = istr_dc_info.istr_is_ld&&(istr_funct3==`ISTR_LD_LHU_FUNCT3    );
/*sd系*/
assign istr_dc_info.istr_is_sd_sb     = istr_dc_info.istr_is_sd&&(istr_funct3==`ISTR_SD_SB_FUNCT3     );
assign istr_dc_info.istr_is_sd_sh     = istr_dc_info.istr_is_sd&&(istr_funct3==`ISTR_SD_SH_FUNCT3     );
assign istr_dc_info.istr_is_sd_sw     = istr_dc_info.istr_is_sd&&(istr_funct3==`ISTR_SD_SW_FUNCT3     );
/*br系*/
assign istr_dc_info.istr_is_br_beq    = istr_dc_info.istr_is_br&&(istr_funct3==`ISTR_BR_BEQ_FUNCT3    );
assign istr_dc_info.istr_is_br_bne    = istr_dc_info.istr_is_br&&(istr_funct3==`ISTR_BR_BNE_FUNCT3    );
assign istr_dc_info.istr_is_br_blt    = istr_dc_info.istr_is_br&&(istr_funct3==`ISTR_BR_BLT_FUNCT3    );
assign istr_dc_info.istr_is_br_bge    = istr_dc_info.istr_is_br&&(istr_funct3==`ISTR_BR_BGE_FUNCT3    );
assign istr_dc_info.istr_is_br_bliu   = istr_dc_info.istr_is_br&&(istr_funct3==`ISTR_BR_BLIU_FUNCT3   );
assign istr_dc_info.istr_is_br_bgeu   = istr_dc_info.istr_is_br&&(istr_funct3==`ISTR_BR_BGEU_FUNCT3   );
/*sys系*/
assign istr_dc_info.istr_is_sys_csrrw = istr_dc_info.istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRW_FUNCT3 );
assign istr_dc_info.istr_is_sys_csrrs = istr_dc_info.istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRS_FUNCT3 );
assign istr_dc_info.istr_is_sys_csrrc = istr_dc_info.istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRC_FUNCT3 );
assign istr_dc_info.istr_is_sys_csrrwi= istr_dc_info.istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRWI_FUNCT3);
assign istr_dc_info.istr_is_sys_csrrsi= istr_dc_info.istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRSI_FUNCT3);
assign istr_dc_info.istr_is_sys_csrrci= istr_dc_info.istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRCI_FUNCT3);

assign istr_dc_info.istr_is_sys_mret  = istr==`ISTR_MRET;
/*
-分辨mret

-分辨wfi
assign      istr_is_sys_wfi   =
-分辨ebrea
assign      istr_is_sys_ebrea =
-分辨ecall
assign      istr_is_sys_ecall =
*/

endmodule
