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
`define MEM_OP_B            (3'd1)
`define MEM_OP_H            (3'd2)
`define MEM_OP_W            (3'd3)
`define MEM_OP_BU           (3'd4)
`define MEM_OP_HU           (3'd5)

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
`define     ISTR_MRET               (32'h30200073)  /*mret指令*/
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

`define     ISTR_RA_SLLI_FUNCT7     (7'b0000000)
`define     ISTR_IA_SRLI_FUNCT7     (7'b0000000)
`define     ISTR_IA_SRAI_FUNCT7     (7'b0100000)
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




`endif
