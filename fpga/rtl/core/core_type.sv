package core_type;
typedef struct
{
  logic        istr_is_ra;          /*10:ADD,SUB,SLL,SLT,SLTU,XOR,SRL,SRA,OR,AND                     */
  logic        istr_is_ia;          /*9 :ADDI,SLTI,SLTIU,XORI,ORI,ANDI,SLLI,SRLI,SRAI                */
  logic        istr_is_ld;          /*4 :LB,LH,LW,LBU,LHU                                            */
  logic        istr_is_sd;          /*3 :SB,SH,SW                                                    */
  logic        istr_is_br;          /*6 :BEQ,BNE,BLT,BGE,BLIU,BGEU                                   */
  logic        istr_is_jr;          /*1 :JALR                                                        */
  logic        istr_is_j;           /*1 :JAL                                                         */
  logic        istr_is_lui;         /*1 :LUI                                                         */
  logic        istr_is_auipc;       /*1 :AUIPC                                                       */
  logic        istr_is_fence;       /*2 :FENCE,FENCE.I                                               */
  logic        istr_is_sys;         /*10:CSRRW,CSRRS,CSRRC,CSRRW,CSRRSI,CSRRCI,WFI,EBREA,BCALL,MRET  */
  /*reg-reg*/
  logic        istr_is_ra_add;
  logic        istr_is_ra_sub;
  logic        istr_is_ra_sll;
  logic        istr_is_ra_slt;
  logic        istr_is_ra_sltu;
  logic        istr_is_ra_xor;
  logic        istr_is_ra_srl;
  logic        istr_is_ra_sra;
  logic        istr_is_ra_or;
  logic        istr_is_ra_and;
  /*imm-reg*/
  logic        istr_is_ia_addi;
  logic        istr_is_ia_slti;
  logic        istr_is_ia_sltiu;
  logic        istr_is_ia_xori;
  logic        istr_is_ia_ori;
  logic        istr_is_ia_andi;
  logic        istr_is_ia_slli;
  logic        istr_is_ia_srli;
  logic        istr_is_ia_srai;
  /*load指令*/
  logic        istr_is_ld_lb;
  logic        istr_is_ld_lh;
  logic        istr_is_ld_lw;
  logic        istr_is_ld_lbu;
  logic        istr_is_ld_lhu;
  /*store指令*/
  logic        istr_is_sd_sb;
  logic        istr_is_sd_sh;
  logic        istr_is_sd_sw;
  /*条件分支指令*/
  logic        istr_is_br_beq;
  logic        istr_is_br_bne;
  logic        istr_is_br_blt;
  logic        istr_is_br_bge;
  logic        istr_is_br_bliu;
  logic        istr_is_br_bgeu;
  /*fence*/
  logic        istr_is_fence_fence;
  logic        istr_is_fence_fencei;
  /*sys指令*/
  logic        istr_is_sys_csrrw;
  logic        istr_is_sys_csrrs;
  logic        istr_is_sys_csrrc;
  logic        istr_is_sys_csrrwi;
  logic        istr_is_sys_csrrsi;
  logic        istr_is_sys_csrrci;
  logic        istr_is_sys_mret;
  logic        istr_is_sys_ebrea;
  logic        istr_is_sys_ecall;
  logic        istr_is_sys_wfi;
}istr_dc_info_t;

typedef struct
{
  logic[3:0]   alu_op;
}istr_alu_dc_info_t;

endpackage