`ifndef __CORE_DEFINE_SV
`define __CORE_DEFINE_SV

/*ALU操作码*/
`define ALU_OP_NOP          (4'd0)
`define ALU_OP_ADD          (4'd1)
`define ALU_OP_SUB          (4'd2)
`define ALU_OP_SLL          (4'd3)
`define ALU_OP_SLT          (4'd4)
`define ALU_OP_SLTU         (4'd5)
`define ALU_OP_XOR          (4'd6)
`define ALU_OP_SRL          (4'd7)
`define ALU_OP_SRA          (4'd8)
`define ALU_OP_OR           (4'd9)
`define ALU_OP_AND          (4'd10)
`define ALU_OP_NOT_AND      (4'd11)

/*MEM操作码*/
`define MEM_OP_B            (4'd1)
`define MEM_OP_H            (4'd2)
`define MEM_OP_W            (4'd3)
`define MEM_OP_BU           (4'd4)
`define MEM_OP_HU           (4'd5)

`define BR_OP_FALSE         (4'd0)
`define BR_OP_TRUE          (4'd1)
`define BR_OP_EQ            (4'd2)
`define BR_OP_NE            (4'd3)
`define BR_OP_LT            (4'd4)
`define BR_OP_GE            (4'd5)
`define BR_OP_LIU           (4'd6)
`define BR_OP_GEU           (4'd7)

/****************************************************************************************
define
****************************************************************************************/
/*opcode*/
`define     ISTR_RA                 (5'b01100)
`define     ISTR_IA                 (5'b00100)
`define     ISTR_LD                 (5'b00000)
`define     ISTR_SD                 (5'b01000)
`define     ISTR_BR                 (5'b11000)
`define     ISTR_JR                 (5'b11001)
`define     ISTR_J                  (5'b11011)
`define     ISTR_LUI                (5'b01101)
`define     ISTR_AUIPC              (5'b00101)
`define     ISTR_FENCE              (5'b00011)
`define     ISTR_SYS                (5'b11100)
/*ISTR_RA funct3字段*/  
`define     ISTR_RA_ADD_FUNCT3      (3'b000)
`define     ISTR_RA_SUB_FUNCT3      (3'b000)
`define     ISTR_RA_SLL_FUNCT3      (3'b001)
`define     ISTR_RA_SLT_FUNCT3      (3'b010)
`define     ISTR_RA_SLTU_FUNCT3     (3'b011)
`define     ISTR_RA_XOR_FUNCT3      (3'b100)
`define     ISTR_RA_SRL_FUNCT3      (3'b101)
`define     ISTR_RA_SRA_FUNCT3      (3'b101)
`define     ISTR_RA_OR_FUNCT3       (3'b110)
`define     ISTR_RA_AND_FUNCT3      (3'b111)
/*ISTR_RA funct7字段*/  
`define     ISTR_RA_ADD_FUNCT7      (7'b0000000)
`define     ISTR_RA_SUB_FUNCT7      (7'b0100000)
`define     ISTR_RA_SLL_FUNCT7      (7'b0000000)
`define     ISTR_RA_SLT_FUNCT7      (7'b0000000)
`define     ISTR_RA_SLTU_FUNCT7     (7'b0000000)
`define     ISTR_RA_XOR_FUNCT7      (7'b0000000)
`define     ISTR_RA_SRL_FUNCT7      (7'b0000000)
`define     ISTR_RA_SRA_FUNCT7      (7'b0100000)
`define     ISTR_RA_OR_FUNCT7       (7'b0000000)
`define     ISTR_RA_AND_FUNCT7      (7'b0000000)
/*ISTR_IA funct3字段*/  
`define     ISTR_IA_ADDI_FUNCT3     (3'b000)
`define     ISTR_IA_SLTI_FUNCT3     (3'b010)
`define     ISTR_IA_SLTIU_FUNCT3    (3'b011)
`define     ISTR_IA_XORI_FUNCT3     (3'b100)
`define     ISTR_IA_ORI_FUNCT3      (3'b110)
`define     ISTR_RA_SLLI_FUNCT3     (3'b001)
`define     ISTR_IA_SRLI_FUNCT3     (3'b101)
`define     ISTR_IA_SRAI_FUNCT3     (3'b101)
`define     ISTR_IA_ANDI_FUNCT3     (3'b111)
/*ISTR_LD funct3字段*/  
`define     ISTR_LD_LB_FUNCT3       (3'b000)
`define     ISTR_LD_LH_FUNCT3       (3'b001)
`define     ISTR_LD_LW_FUNCT3       (3'b010)
`define     ISTR_LD_LBU_FUNCT3      (3'b100)
`define     ISTR_LD_LHU_FUNCT3      (3'b101)
/*ISTR_SD funct3字段*/  
`define     ISTR_SD_SB_FUNCT3       (3'b000)
`define     ISTR_SD_SH_FUNCT3       (3'b001)
`define     ISTR_SD_SW_FUNCT3       (3'b010)
/*ISTR_BR funct3字段*/  
`define     ISTR_BR_BEQ_FUNCT3      (3'b000)
`define     ISTR_BR_BNE_FUNCT3      (3'b001)
`define     ISTR_BR_BLT_FUNCT3      (3'b100)
`define     ISTR_BR_BGE_FUNCT3      (3'b101)
`define     ISTR_BR_BLIU_FUNCT3     (3'b110)
`define     ISTR_BR_BGEU_FUNCT3     (3'b111)
/*ISTR_SYS funct3字段*/
`define     ISTR_SYS_CSRRW_FUNCT3   (3'b001)
`define     ISTR_SYS_CSRRS_FUNCT3   (3'b010)
`define     ISTR_SYS_CSRRC_FUNCT3   (3'b011)
`define     ISTR_SYS_CSRRWI_FUNCT3  (3'b101)
`define     ISTR_SYS_CSRRSI_FUNCT3  (3'b110)
`define     ISTR_SYS_CSRRCI_FUNCT3  (3'b111)
`define     ISTR_SYS_MRET_FUNCT3    (3'b000)
`define     ISTR_SYS_WFI_FUNCT3     (3'b000)
`define     ISTR_SYS_EBREA_FUNCT3   (3'b000)
`define     ISTR_SYS_ECALL_FUNCT3   (3'b000)

package core_define;
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


`endif
