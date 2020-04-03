`include "core_define.sv"
module core_id(
  input  logic          clk,
  input  logic          rest,
  /*来自if级的信号*/ 
  input  logic          fd_valid,
  output logic          fd_ready,
  input  logic[31:0]    fd_istr,
  input  logic[31:0]    fd_pc,
  input  logic          fd_jump,
  input  logic          fd_istr_width,
  /*来自ex级的信号*/
  input  logic          ex_flush_en,
  /*来自wb级的信号*/
  input  logic          wd_valid,
  output logic          wd_ready,
  input  logic[31:0]    wd_reg_data,
  input  logic[4:0]     wd_rd,
  input  logic          wd_reg_write,
  input  logic[31:0]    wd_csr_data,
  input  logic[11:0]    wd_csr,
  input  logic          wd_csr_write,
  /*给到ex*/
  output logic          de_valid,
  output logic          de_wait_handle,
  input  logic          de_ready,
  output logic[3:0]     de_alu_op,
  output logic[31:0]    de_rs1_value,
  output logic[31:0]    de_csr_valud,
  output logic[4:0]     de_zimm,
  output logic[31:0]    de_pc,
  output logic[31:0]    de_rs2_value,
  output logic[31:0]    de_imm,       /*指令中的立即数*/
  output logic[11:0]    de_csr,
  output logic[4:0]     de_rd,
  output logic          de_reg_write,
  output logic          de_csr_write,
  output logic          de_mem_write,
  output logic          de_mem_read,
  output logic          de_mem_op,
  output logic          de_istr_width,
  output logic          de_is_br,      /*是否为分支指令*/
  output logic[3:0]     de_br_op,      /*分支需要进行的比较操作:等于?，不等于?,或者恒为真/假*/
  output logic          de_jump,       /*这条指令是否在前面已经跳转了*/
  output logic[4:0]     de_rs1,
  output logic[4:0]     de_rs2,
  /*csr接口*/
  output logic          csr_read,
  output logic[11:0]    csr_read_addr,
  input  logic[31:0]    csr_read_data,
  output logic          csr_write,
  output logic[11:0]    csr_write_addr,
  output logic[31:0]    csr_write_data
);
/****************************************************************************************
函数
****************************************************************************************/
/*获取I类型指令的立即数(有符号)*/
function logic[31:0] istr_get_imm_i(logic[31:0] istr);
  return {{20{istr[31]}},istr[31:20]};
endfunction
/*获取I类型指令的立即数(无符号)*/
function logic[31:0] istr_get_imm_i_u(logic[31:0] istr);
  return {{20{istr[31]}},istr[31:20]};
endfunction
/*获取S类型指令的立即数*/
function logic[31:0] istr_get_imm_s(logic[31:0] istr);
  return {{20{istr[31]}},istr[31:25],istr[11:7]};
endfunction
/*获取SB类型指令的立即数*/
function logic[31:0] istr_get_imm_sb(logic[31:0] istr);
  return {{19{istr[31]}},istr[31],istr[7],istr[30:25],istr[11:8],1'd0};
endfunction
/*获取U类型指令的立即数*/
function logic[31:0] istr_get_imm_u(logic[31:0] istr);
  return {istr[31:12],12'd0};
endfunction
/*获取UI类型指令的立即数*/
function logic[31:0] istr_get_imm_ui(logic[31:0] istr);
  return {{11{istr[31]}},istr[31],istr[19:12],istr[20],istr[30:21],1'b0};
endfunction

function logic[31:0] istr_get_imm (logic [31:0] istr);
/*从指令中获取立即数*/
  logic[31:0] imm;
  case(istr[6:2])
    5'b00100:begin
        if(istr[14:12]==`ISTR_IA_SLTIU_FUNCT3) begin
          imm=istr_get_imm_i_u(istr);  /*立即数与寄存器中数据的算术操作*/
        end
        else begin
          imm=istr_get_imm_i(istr);   /*立即数与寄存器中数据的算术操作*/
        end
      end
    5'b00000:imm=istr_get_imm_i(istr);  /*Load指令的地址偏移*/
    5'b01000:imm=istr_get_imm_s(istr);  /*Store指令的地址偏移*/
    5'b11000:imm=istr_get_imm_sb(istr); /*分支指令的地址偏移*/
    5'b11011:imm=istr_get_imm_ui(istr); /*JAL指令的地址偏移*/
    5'b11001:imm=istr_get_imm_i(istr);  /*JALR指令的地址偏移*/
    5'b01101:imm=istr_get_imm_u(istr);  /*LUI指令的立即数*/
    5'b00101:imm=istr_get_imm_u(istr);  /*AUIPC指令的立即数*/
    default:begin
      imm=1'd0;
    end
  endcase
  return imm;
endfunction
/*zimm*/
function logic[4:0] istr_get_zimm(logic[31:0] istr);
  return istr[19:15];
endfunction
/*csr*/
function logic[11:0] istr_get_csr(logic[31:0] istr);
  return istr[31:20];
endfunction

/****************************************************************************************
变量
****************************************************************************************/
/*指令字段*/
logic[4:0]   istr_opcode;
logic[2:0]   istr_funct3;
logic[6:0]   istr_funct7;
logic[4:0]   istr_rd;
logic[4:0]   istr_rs1;
logic[4:0]   istr_rs2;
/*寄存器文件端口*/
logic[4:0]   reg_file_read_0_addr;
logic[31:0]  reg_file_read_0_data;
logic[4:0]   reg_file_read_1_addr;
logic[31:0]  reg_file_read_1_data;
logic[4:0]   reg_file_write_addr;
logic[31:0]  reg_file_write_data;
logic        reg_file_write_en;
/*指令译码相关变量*/
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

/*ALU操作码选择信号*/
logic        alu_op_is_add;
logic        alu_op_is_sub;
logic        alu_op_is_sll;
logic        alu_op_is_slt;
logic        alu_op_is_sltu;
logic        alu_op_is_xor;
logic        alu_op_is_srl;
logic        alu_op_is_sra;
logic        alu_op_is_or;
logic        alu_op_is_and;
logic        alu_op_is_not_and;
/*alu opcode*/
logic[3:0]   alu_op;
/*其它信号判断*/
logic        reg_write_en;
logic        csr_write_en;
logic        mem_write_en;
logic        mem_read_en;
logic        mem_op;
logic        istr_width;
logic        is_br;
logic[3:0]   br_op;
logic        jump;

/****************************************************************************************
译码
****************************************************************************************/
/*字段分离*/
assign       istr_opcode      = fd_istr[6:2];
assign       istr_funct3      = fd_istr[14:12];
assign       istr_funct7      = fd_istr[31:25];
assign       istr_rd          = fd_istr[11: 7];
assign       istr_rs1         = fd_istr[19:15];
assign       istr_rs2         = fd_istr[24:20];
/*opcode decode*/
assign       istr_is_ra       = istr_opcode==`ISTR_RA;
assign       istr_is_ia       = istr_opcode==`ISTR_RA;
assign       istr_is_ld       = istr_opcode==`ISTR_LD;
assign       istr_is_sd       = istr_opcode==`ISTR_SD;
assign       istr_is_br       = istr_opcode==`ISTR_BR;
assign       istr_is_jr       = istr_opcode==`ISTR_JR;
assign       istr_is_j        = istr_opcode==`ISTR_J;
assign       istr_is_lui      = istr_opcode==`ISTR_LUI;
assign       istr_is_auipc    = istr_opcode==`ISTR_AUIPC;
assign       istr_is_fence    = istr_opcode==`ISTR_FENCE;
assign       istr_is_sys      = istr_opcode==`ISTR_SYS;
/*ra系*/
assign       istr_is_ra_add   = istr_is_ra&&((istr_funct3==`ISTR_RA_ADD_FUNCT3   )&&(istr_funct7==`ISTR_RA_ADD_FUNCT7   ));
assign       istr_is_ra_sub   = istr_is_ra&&((istr_funct3==`ISTR_RA_SUB_FUNCT3   )&&(istr_funct7==`ISTR_RA_SUB_FUNCT7   ));
assign       istr_is_ra_sll   = istr_is_ra&&((istr_funct3==`ISTR_RA_SLL_FUNCT3   )&&(istr_funct7==`ISTR_RA_SLL_FUNCT7   ));
assign       istr_is_ra_slt   = istr_is_ra&&((istr_funct3==`ISTR_RA_SLT_FUNCT3   )&&(istr_funct7==`ISTR_RA_SLT_FUNCT7   ));
assign       istr_is_ra_sltu  = istr_is_ra&&((istr_funct3==`ISTR_RA_SLTU_FUNCT3  )&&(istr_funct7==`ISTR_RA_SLTU_FUNCT7  ));
assign       istr_is_ra_xor   = istr_is_ra&&((istr_funct3==`ISTR_RA_XOR_FUNCT3   )&&(istr_funct7==`ISTR_RA_XOR_FUNCT7   ));
assign       istr_is_ra_srl   = istr_is_ra&&((istr_funct3==`ISTR_RA_SRL_FUNCT3   )&&(istr_funct7==`ISTR_RA_SRL_FUNCT7   ));
assign       istr_is_ra_sra   = istr_is_ra&&((istr_funct3==`ISTR_RA_SRA_FUNCT3   )&&(istr_funct7==`ISTR_RA_SRA_FUNCT7   ));
assign       istr_is_ra_or    = istr_is_ra&&((istr_funct3==`ISTR_RA_OR_FUNCT3    )&&(istr_funct7==`ISTR_RA_OR_FUNCT7    ));
assign       istr_is_ra_and   = istr_is_ra&&((istr_funct3==`ISTR_RA_AND_FUNCT3   )&&(istr_funct7==`ISTR_RA_AND_FUNCT7   ));
/*ia系*/
assign      istr_is_ia_addi   = istr_is_ia&&((istr_funct3==`ISTR_IA_ADDI_FUNCT3  )&&(istr_funct7==`ISTR_IA_ADDI_FUNCT7  ));
assign      istr_is_ia_slti   = istr_is_ia&&((istr_funct3==`ISTR_IA_SLTI_FUNCT3  )&&(istr_funct7==`ISTR_IA_SLTI_FUNCT7  ));
assign      istr_is_ia_sltiu  = istr_is_ia&&((istr_funct3==`ISTR_IA_SLTIU_FUNCT3 )&&(istr_funct7==`ISTR_IA_SLTIU_FUNCT7 ));
assign      istr_is_ia_xori   = istr_is_ia&&((istr_funct3==`ISTR_IA_XORI_FUNCT3  )&&(istr_funct7==`ISTR_IA_XORI_FUNCT7  ));
assign      istr_is_ia_ori    = istr_is_ia&&((istr_funct3==`ISTR_IA_ORI_FUNCT3   )&&(istr_funct7==`ISTR_IA_ORI_FUNCT7   ));
assign      istr_is_ia_andi   = istr_is_ia&&((istr_funct3==`ISTR_IA_ANDI_FUNCT3  )&&(istr_funct7==`ISTR_IA_ANDI_FUNCT7  ));
assign      istr_is_ia_slli   = istr_is_ia&&((istr_funct3==`ISTR_RA_SLLI_FUNCT3  )&&(istr_funct7==`ISTR_RA_SLLI_FUNCT7  ));
assign      istr_is_ia_srli   = istr_is_ia&&((istr_funct3==`ISTR_IA_SRLI_FUNCT3  )&&(istr_funct7==`ISTR_IA_SRLI_FUNCT7  ));
assign      istr_is_ia_srai   = istr_is_ia&&((istr_funct3==`ISTR_IA_SRAI_FUNCT3  )&&(istr_funct7==`ISTR_IA_SRAI_FUNCT7  ));
/*ld系*/
assign      istr_is_ld_lb     = istr_is_ld&&(istr_funct3==`ISTR_LD_LB_FUNCT3     );
assign      istr_is_ld_lh     = istr_is_ld&&(istr_funct3==`ISTR_LD_LH_FUNCT3     );
assign      istr_is_ld_lw     = istr_is_ld&&(istr_funct3==`ISTR_LD_LW_FUNCT3     );
assign      istr_is_ld_lbu    = istr_is_ld&&(istr_funct3==`ISTR_LD_LBU_FUNCT3    );
assign      istr_is_ld_lhu    = istr_is_ld&&(istr_funct3==`ISTR_LD_LHU_FUNCT3    );
/*sd系*/
assign      istr_is_sd_sb     = istr_is_sd&&(istr_funct3==`ISTR_SD_SB_FUNCT3     );
assign      istr_is_sd_sh     = istr_is_sd&&(istr_funct3==`ISTR_SD_SH_FUNCT3     );
assign      istr_is_sd_sw     = istr_is_sd&&(istr_funct3==`ISTR_SD_SW_FUNCT3     );
/*br系*/
assign      istr_is_br_beq    = istr_is_br&&(istr_funct3==`ISTR_BR_BEQ_FUNCT3    );
assign      istr_is_br_bne    = istr_is_br&&(istr_funct3==`ISTR_BR_BNE_FUNCT3    );
assign      istr_is_br_blt    = istr_is_br&&(istr_funct3==`ISTR_BR_BLT_FUNCT3    );
assign      istr_is_br_bge    = istr_is_br&&(istr_funct3==`ISTR_BR_BGE_FUNCT3    );
assign      istr_is_br_bliu   = istr_is_br&&(istr_funct3==`ISTR_BR_BLIU_FUNCT3   );
assign      istr_is_br_bgeu   = istr_is_br&&(istr_funct3==`ISTR_BR_BGEU_FUNCT3   );
/*sys系*/
assign      istr_is_sys_csrrw = istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRW_FUNCT3 );
assign      istr_is_sys_csrrs = istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRS_FUNCT3 );
assign      istr_is_sys_csrrc = istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRC_FUNCT3 );
assign      istr_is_sys_csrrwi= istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRWI_FUNCT3);
assign      istr_is_sys_csrrsi= istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRSI_FUNCT3);
assign      istr_is_sys_csrrci= istr_is_sys&&(istr_funct3==`ISTR_SYS_CSRRCI_FUNCT3);
/*
-分辨mret
assign      istr_is_sys_mret  =
-分辨wfi
assign      istr_is_sys_wfi   =
-分辨ebrea
assign      istr_is_sys_ebrea =
-分辨ecall
assign      istr_is_sys_ecall =
*/

assign      alu_op_is_add     = istr_is_ra_add      ||istr_is_ia_addi||
                                istr_is_ld          ||istr_is_sd     ||
                                istr_is_br          ||istr_is_jr     ||
                                istr_is_j           ||istr_is_auipc;
assign      alu_op_is_sub     = istr_is_ra_sub;
assign      alu_op_is_sll     = istr_is_ra_sll      ||istr_is_ia_slli;
assign      alu_op_is_slt     = istr_is_ra_slt      ||istr_is_ia_slti;
assign      alu_op_is_sltu    = istr_is_ra_sltu     ||istr_is_ia_sltiu;
assign      alu_op_is_xor     = istr_is_ra_xor      ||istr_is_ia_xori;
assign      alu_op_is_srl     = istr_is_ra_srl      ||istr_is_ia_srli;
assign      alu_op_is_sra     = istr_is_ra_sra      ||istr_is_ia_srai;
assign      alu_op_is_or      = istr_is_ra_or       ||istr_is_ia_ori ||
                                istr_is_sys_csrrs   ||istr_is_sys_csrrsi;
assign      alu_op_is_and     = istr_is_ra_and      ||istr_is_ia_andi;
assign      alu_op_is_not_and = istr_is_sys_csrrc   ||istr_is_sys_csrrci;

/*得出de寄存器组的值*/
assign      alu_op            = {4{alu_op_is_add    }}&`ALU_OP_ADD  ||
                                {4{alu_op_is_sub    }}&`ALU_OP_SUB  ||
                                {4{alu_op_is_sll    }}&`ALU_OP_SLL  ||
                                {4{alu_op_is_slt    }}&`ALU_OP_SLT  ||
                                {4{alu_op_is_sltu   }}&`ALU_OP_SLTU ||
                                {4{alu_op_is_xor    }}&`ALU_OP_XOR  ||
                                {4{alu_op_is_srl    }}&`ALU_OP_SRL  ||
                                {4{alu_op_is_sra    }}&`ALU_OP_SRA  ||
                                {4{alu_op_is_or     }}&`ALU_OP_OR   ||
                                {4{alu_op_is_and    }}&`ALU_OP_AND  ||
                                {4{alu_op_is_not_and}}&`ALU_OP_NOT_AND;
assign      reg_write_en      = (istr_rd!=1'd0)&&(istr_is_ra||istr_is_ia  ||
                                                  istr_is_ld||istr_is_sys ||
                                                  istr_is_jr||istr_is_lui ||
                                                  istr_is_j ||istr_is_auipc);
assign      csr_write_en      = istr_is_sys_csrrw ||
                                istr_is_sys_csrrs ||
                                istr_is_sys_csrrc ||
                                istr_is_sys_csrrwi||
                                istr_is_sys_csrrsi||
                                istr_is_sys_csrrci;
assign      mem_write_en      = istr_is_sd;
assign      mem_read_en       = istr_is_ld;
assign      mem_op            = ({4{istr_is_ld_lb|istr_is_sd_sb}})&`MEM_OP_B ||
                                ({4{istr_is_ld_lh|istr_is_sd_sh}})&`MEM_OP_H ||
                                ({4{istr_is_ld_lw|istr_is_sd_sw}})&`MEM_OP_W ||
                                ({4{istr_is_ld_lbu             }})&`MEM_OP_BU||
                                ({4{istr_is_ld_lhu             }})&`MEM_OP_HU;
assign      is_br             = istr_is_br||istr_is_j||istr_is_jr||istr_is_sys_mret;
assign      br_op             = (istr_is_j||istr_is_jr||istr_is_sys_mret)?`BR_OP_TRUE:
                                  ({4{istr_is_br_beq }}&`BR_OP_EQ) ||
                                  ({4{istr_is_br_bne }}&`BR_OP_NE) ||
                                  ({4{istr_is_br_blt }}&`BR_OP_LT) ||
                                  ({4{istr_is_br_bge }}&`BR_OP_GE) ||
                                  ({4{istr_is_br_bliu}}&`BR_OP_LIU)||
                                  ({4{istr_is_br_bgeu}}&`BR_OP_GEU);

always @(posedge clk) begin
  if(ex_flush_en) begin
    de_valid<=1'd0;
    de_wait_handle<=1'd0;
  end
  else if(!de_valid||de_ready) begin
    de_valid<=fd_valid;
    de_wait_handle<=1'd1;
    /*更新de寄存器组*/
    de_alu_op     <= alu_op;
    de_zimm       <= istr_get_zimm(fd_istr);
    de_pc         <= fd_pc;
    de_imm        <= istr_get_imm(fd_istr);
    de_csr        <= istr_get_csr(fd_istr);
    de_rd         <= istr_rd;
    de_reg_write  <= reg_write_en;
    de_csr_write  <= csr_write_en;
    de_mem_write  <= mem_write_en;
    de_mem_read   <= mem_read_en;
    de_mem_op     <= mem_op;
    de_istr_width <= fd_istr_width;
    de_is_br      <= is_br;
    de_br_op      <= br_op;
    de_jump       <= fd_jump;
    de_rs1        <= istr_rs1;
    de_rs2        <= istr_rs2;
  end begin
    de_wait_handle<=1'd0;
  end
end
assign de_rs1_value=reg_file_read_0_data;
assign de_rs2_value=reg_file_read_1_data;
assign de_csr_valud=csr_read_data;

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

/*****************************************************************************************************************
根据指令获取其中的立即数
*****************************************************************************************************************/

