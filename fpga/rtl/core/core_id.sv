`include "core_define.sv"

import core_define::*;

module core_id(
  /*clk,rest*/
  input  logic       clk,
  input  logic       rest,
  /*来自if级的信号*/
  input  logic       fd_valid,
  output logic       fd_ready,
  input  logic[31:0] fd_istr,
  input  logic[31:0] fd_pc,
  input  logic       fd_jump,
  /*给到ex*/
  output logic       de_valid,
  output logic       de_start_handle,
  input  logic       de_ready,
  output logic[3:0]  de_alu_op,
  output logic[31:0] de_rs1_value,
  output logic[31:0] de_csr_value,
  output logic[4:0]  de_zimm,
  output logic[31:0] de_pc,
  output logic[31:0] de_rs2_value,
  output logic[31:0] de_imm,       /*指令中的立即数*/
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
  output logic[11:0] de_csr,
  output logic       de_csr_valid,
  output logic[4:0]  de_rs1,
  output logic[4:0]  de_rs2,
  output logic       de_rs1_valid,
  output logic       de_rs2_valid,
  output logic[1:0]  de_alu_in_1_sel,
  output logic[1:0]  de_alu_in_2_sel,
  output logic[1:0]  de_em_reg_data_mem_addr_sel,
  output logic[1:0]  de_em_csr_data_mem_data_sel,
  /*来自wb级的信号*/
  input  logic       wb_valid,
  output logic       wb_ready,
  input  logic[31:0] wb_reg_data,
  input  logic[4:0]  wb_rd,
  input  logic       wb_reg_write,
  input  logic[31:0] wb_csr_data,
  input  logic[11:0] wb_csr,
  input  logic       wb_csr_write,
  /*来自ex级的信号*/
  input  logic       ex_flush_en,
  /*csr接口*/
  output logic       csr_read,
  output logic[11:0] csr_read_addr,
  input  logic[31:0] csr_read_data,
  output logic       csr_write,
  output logic[11:0] csr_write_addr,
  output logic[31:0] csr_write_data,
  /*冲突检测*/
  input  logic[4:0]  em_rd,
  input  logic       em_reg_write,
  input  logic       em_mem_read
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
/*从指令中获取立即数*/
function logic[31:0] istr_get_imm (logic [31:0] istr);
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
logic[31:0]  istr;
logic[31:0]  istr_from_c;
logic[4:0]   istr_rd;
logic[4:0]   istr_rs1;
logic[4:0]   istr_rs2;
/*寄存器文件端口*/
logic[4:0]   reg_file_read_0_addr;
logic[31:0]  reg_file_read_0_data;
logic        reg_file_read_0_en;
logic[4:0]   reg_file_read_1_addr;
logic[31:0]  reg_file_read_1_data;
logic        reg_file_read_1_en;
logic[4:0]   reg_file_write_addr;
logic[31:0]  reg_file_write_data;
logic        reg_file_write_en;
/*冲突检测端口*/
logic[4:0]   risk_detct_rs1;
logic        risk_detct_rs1_valid;
logic[4:0]   risk_detct_rs2;
logic        risk_detct_rs2_valid;
logic        risk_detct_mem_write;
logic[4:0]   risk_detct_de_rd;
logic        risk_detct_de_reg_write;
logic        risk_detct_de_mem_read;
logic[4:0]   risk_detct_em_rd;
logic        risk_detct_em_reg_write;
logic        risk_detct_em_mem_read;
logic        risk_detct_insert_nop;

istr_dc_info_t      istr_dc_info;
istr_alu_dc_info_t  istr_alu_dc_info;

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
logic        rs1_valid;
logic        rs2_valid;
logic[1:0]   alu_port_1_sel;
logic[1:0]   alu_port_2_sel;
logic[1:0]   em_reg_data_addr_sel;
logic[1:0]   em_csr_data_sel;

logic        alu_in_1_sel_is_rs1;
logic        alu_in_1_sel_is_zimm;
logic        alu_in_1_sel_is_pc;
logic[1:0]   alu_in_1_sel;
logic        alu_in_2_sel_is_rs2;              
logic        alu_in_2_sel_is_imm;
logic        alu_in_2_sel_is_csr;
logic[1:0]   alu_in_2_sel;
logic        reg_data_mem_addr_sel_is_alu;
logic        reg_data_mem_addr_sel_is_imm;
logic        reg_data_mem_addr_sel_is_csr;
logic        reg_data_mem_addr_sel_is_pc_add;
logic[1:0]   reg_data_mem_addr_sel;
logic        csr_data_mem_data_sel_is_alu;     
logic        csr_data_mem_data_sel_is_rs1;
logic[1:0]   csr_data_mem_data_sel;            
/****************************************************************************************
译码
****************************************************************************************/
/*字段分离*/
assign istr              = (fd_istr[1:0]==2'd3)?fd_istr:istr_from_c;
assign istr_rd           = istr[11: 7];
assign istr_rs1          = istr[19:15];
assign istr_rs2          = istr[24:20];

assign      reg_write_en      = (istr_rd!=1'd0)&&(istr_dc_info.istr_is_ra||istr_dc_info.istr_is_ia  ||
                                                  istr_dc_info.istr_is_ld||istr_dc_info.istr_is_sys ||
                                                  istr_dc_info.istr_is_jr||istr_dc_info.istr_is_lui ||
                                                  istr_dc_info.istr_is_j ||istr_dc_info.istr_is_auipc);
assign      csr_write_en      = istr_dc_info.istr_is_sys_csrrw ||
                                istr_dc_info.istr_is_sys_csrrs ||
                                istr_dc_info.istr_is_sys_csrrc ||
                                istr_dc_info.istr_is_sys_csrrwi||
                                istr_dc_info.istr_is_sys_csrrsi||
                                istr_dc_info.istr_is_sys_csrrci;
assign      mem_write_en      = istr_dc_info.istr_is_sd;
assign      mem_read_en       = istr_dc_info.istr_is_ld;
assign      mem_op            = ({4{istr_dc_info.istr_is_ld_lb||istr_dc_info.istr_is_sd_sb}})&`MEM_OP_B ||
                                ({4{istr_dc_info.istr_is_ld_lh||istr_dc_info.istr_is_sd_sh}})&`MEM_OP_H ||
                                ({4{istr_dc_info.istr_is_ld_lw||istr_dc_info.istr_is_sd_sw}})&`MEM_OP_W ||
                                ({4{istr_dc_info.istr_is_ld_lbu             }})&`MEM_OP_BU||
                                ({4{istr_dc_info.istr_is_ld_lhu             }})&`MEM_OP_HU;
assign      is_br             = istr_dc_info.istr_is_br ||
                                istr_dc_info.istr_is_j  ||
                                istr_dc_info.istr_is_jr ||
                                istr_dc_info.istr_is_sys_mret;
assign      br_op             = (istr_dc_info.istr_is_j||istr_dc_info.istr_is_jr||istr_dc_info.istr_is_sys_mret)?`BR_OP_TRUE:
                                  ({4{istr_dc_info.istr_is_br_beq }}&`BR_OP_EQ) |
                                  ({4{istr_dc_info.istr_is_br_bne }}&`BR_OP_NE) |
                                  ({4{istr_dc_info.istr_is_br_blt }}&`BR_OP_LT) |
                                  ({4{istr_dc_info.istr_is_br_bge }}&`BR_OP_GE) |
                                  ({4{istr_dc_info.istr_is_br_bliu}}&`BR_OP_LIU)|
                                  ({4{istr_dc_info.istr_is_br_bgeu}}&`BR_OP_GEU);
assign      rs1_valid         = istr_dc_info.istr_is_ra       ||
                                istr_dc_info.istr_is_ia       ||
                                istr_dc_info.istr_is_ld       ||
                                istr_dc_info.istr_is_sd       ||
                                istr_dc_info.istr_is_br       ||
                                istr_dc_info.istr_is_sys_csrrw||
                                istr_dc_info.istr_is_sys_csrrs||
                                istr_dc_info.istr_is_sys_csrrc||
                                istr_dc_info.istr_is_jr;
assign      rs2_valid         = istr_dc_info.istr_is_ra       ||
                                istr_dc_info.istr_is_sd       ||
                                istr_dc_info.istr_is_br;

assign alu_in_1_sel_is_rs1              = istr_dc_info.istr_is_ra       ||
                                          istr_dc_info.istr_is_ia       ||
                                          istr_dc_info.istr_is_ld       ||
                                          istr_dc_info.istr_is_sd       ||
                                          istr_dc_info.istr_is_sys_csrrw||
                                          istr_dc_info.istr_is_sys_csrrs||
                                          istr_dc_info.istr_is_sys_csrrc;
assign alu_in_1_sel_is_zimm             = istr_dc_info.istr_is_sys_csrrwi||
                                          istr_dc_info.istr_is_sys_csrrsi||
                                          istr_dc_info.istr_is_sys_csrrci;
assign alu_in_1_sel_is_pc               = istr_dc_info.istr_is_br||
                                          istr_dc_info.istr_is_lui||
                                          istr_dc_info.istr_is_auipc||
                                          istr_dc_info.istr_is_j;
assign alu_in_1_sel                     = {2{alu_in_1_sel_is_rs1 }}&2'd0|
                                          {2{alu_in_1_sel_is_zimm}}&2'd1|
                                          {2{alu_in_1_sel_is_pc  }}&2'd2;
assign alu_in_2_sel_is_rs2              = istr_dc_info.istr_is_ra;
assign alu_in_2_sel_is_imm              = istr_dc_info.istr_is_ia||
                                          istr_dc_info.istr_is_ld||
                                          istr_dc_info.istr_is_sd||
                                          istr_dc_info.istr_is_br||
                                          istr_dc_info.istr_is_lui||
                                          istr_dc_info.istr_is_auipc||
                                          istr_dc_info.istr_is_jr||
                                          istr_dc_info.istr_is_j;
assign alu_in_2_sel_is_csr              = istr_dc_info.istr_is_sys_csrrw ||
                                          istr_dc_info.istr_is_sys_csrrs ||
                                          istr_dc_info.istr_is_sys_csrrc ||
                                          istr_dc_info.istr_is_sys_csrrwi||
                                          istr_dc_info.istr_is_sys_csrrsi||
                                          istr_dc_info.istr_is_sys_csrrci;
assign alu_in_2_sel                     = {2{alu_in_2_sel_is_rs2 }}&2'd0|
                                          {2{alu_in_2_sel_is_imm }}&2'd1|
                                          {2{alu_in_2_sel_is_csr }}&2'd2;
assign reg_data_mem_addr_sel_is_alu     = istr_dc_info.istr_is_ra||
                                          istr_dc_info.istr_is_ia||
                                          istr_dc_info.istr_is_ld||
                                          istr_dc_info.istr_is_sd||
                                          istr_dc_info.istr_is_sys_csrrs ||
                                          istr_dc_info.istr_is_sys_csrrc ||
                                          istr_dc_info.istr_is_sys_csrrsi||
                                          istr_dc_info.istr_is_sys_csrrci;
assign reg_data_mem_addr_sel_is_imm     = istr_dc_info.istr_is_lui||
                                          istr_dc_info.istr_is_auipc;
assign reg_data_mem_addr_sel_is_csr     = istr_dc_info.istr_is_sys_csrrw||
                                          istr_dc_info.istr_is_sys_csrrwi;
assign reg_data_mem_addr_sel_is_pc_add  = istr_dc_info.istr_is_jr||
                                          istr_dc_info.istr_is_j||
                                          istr_dc_info.istr_is_br;
assign reg_data_mem_addr_sel            = {2{reg_data_mem_addr_sel_is_alu   }}&2'd0|
                                          {2{reg_data_mem_addr_sel_is_imm   }}&2'd1|
                                          {2{reg_data_mem_addr_sel_is_csr   }}&2'd2|
                                          {2{reg_data_mem_addr_sel_is_pc_add}}&2'd3;

assign csr_data_mem_data_sel_is_alu     = !csr_data_mem_data_sel_is_rs1;
assign csr_data_mem_data_sel_is_rs1     = istr_dc_info.istr_is_sd||
                                          istr_dc_info.istr_is_sys_csrrw ||
                                          istr_dc_info.istr_is_sys_csrrs ||
                                          istr_dc_info.istr_is_sys_csrrc ||
                                          istr_dc_info.istr_is_sys_csrrwi||
                                          istr_dc_info.istr_is_sys_csrrsi||
                                          istr_dc_info.istr_is_sys_csrrci;
assign csr_data_mem_data_sel            = {2{csr_data_mem_data_sel_is_alu}}&2'd0|
                                          {2{csr_data_mem_data_sel_is_rs1}}&2'd1;

/*连接reg file与csr寄存器*/
assign reg_file_read_0_addr   =  istr_rs1;
assign reg_file_read_1_addr   =  istr_rs2;
assign reg_file_read_0_en     =  de_ready;
assign reg_file_read_1_en     =  de_ready;
assign csr_read_addr          =  istr_get_csr(istr);
assign csr_read               =  (istr_dc_info.istr_is_sys_csrrw ||
                                  istr_dc_info.istr_is_sys_csrrs ||
                                  istr_dc_info.istr_is_sys_csrrc ||
                                  istr_dc_info.istr_is_sys_csrrwi||
                                  istr_dc_info.istr_is_sys_csrrsi||
                                  istr_dc_info.istr_is_sys_csrrci)&&de_ready;
assign reg_file_write_en      =  wb_reg_write&wb_valid;
assign reg_file_write_addr    =  wb_rd;
assign reg_file_write_data    =  wb_reg_data;
assign csr_write              =  wb_csr_write&wb_valid;
assign csr_write_addr         =  wb_csr;
assign csr_write_data         =  wb_csr_data; 
assign fd_ready               =  de_ready&&!risk_detct_insert_nop;
assign wb_ready               =  1'd1;

/*连接冒险检测*/
assign risk_detct_rs1           = istr_rs1;
assign risk_detct_rs1_valid     = rs1_valid;
assign risk_detct_rs2           = istr_rs2;
assign risk_detct_rs2_valid     = rs2_valid;
assign risk_detct_mem_write     = mem_write_en;
assign risk_detct_de_rd         = de_rd;
assign risk_detct_de_reg_write  = de_reg_write;
assign risk_detct_de_mem_read   = de_mem_read;
assign risk_detct_em_rd         = em_rd;
assign risk_detct_em_reg_write  = em_reg_write;
assign risk_detct_em_mem_read   = em_mem_read;

/****************************************************************************************
更新寄存器
****************************************************************************************/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    de_valid<=1'd0;
    de_start_handle<=1'd0;
    de_alu_op     <= `ALU_OP_NOP;
    de_br_op      <= `BR_OP_FALSE;
    de_jump       <= 1'd0;
    de_reg_write  <= 1'd0;
    de_csr_write  <= 1'd0;
    de_mem_write  <= 1'd0;
    de_mem_read   <= 1'd0;
  end
  else begin
    if(ex_flush_en) begin
      de_valid<=1'd0;
      de_start_handle<=1'd0;
    end
    else if(!de_valid||de_ready) begin
      de_valid<=fd_valid;
      de_start_handle<=1'd1;
      /*更新de寄存器组*/
      de_zimm                     <= istr_get_zimm(istr);
      de_pc                       <= fd_pc;
      de_imm                      <= istr_get_imm(istr);
      de_csr                      <= istr_get_csr(istr);
      de_rd                       <= istr_rd;
      de_mem_op                   <= mem_op;
      de_istr_width               <= fd_istr[1:0]==2'd3;
      de_is_br                    <= is_br;
      de_rs1                      <= istr_rs1;
      de_rs2                      <= istr_rs2;
      de_rs1_valid                <= rs1_valid;
      de_rs2_valid                <= rs2_valid;
      de_alu_in_1_sel             <= alu_in_1_sel;
      de_alu_in_2_sel             <= alu_in_2_sel;
      de_em_reg_data_mem_addr_sel <= reg_data_mem_addr_sel;
      de_em_csr_data_mem_data_sel <= csr_data_mem_data_sel;
      if(!risk_detct_insert_nop) begin
        de_alu_op     <= istr_alu_dc_info.alu_op;
        de_br_op      <= br_op;
        de_jump       <= fd_jump;
        de_reg_write  <= reg_write_en;
        de_csr_write  <= csr_write_en;
        de_mem_write  <= mem_write_en;
        de_mem_read   <= mem_read_en;
      end
      else begin
        de_alu_op     <= `ALU_OP_NOP;
        de_br_op      <= `BR_OP_FALSE;
        de_jump       <= 1'd0;
        de_reg_write  <= 1'd0;
        de_csr_write  <= 1'd0;
        de_mem_write  <= 1'd0;
        de_mem_read   <= 1'd0;
      end
    end begin
      de_start_handle<=1'd0;
    end
  end
end
assign de_rs1_value=reg_file_read_0_data;
assign de_rs2_value=reg_file_read_1_data;
assign de_csr_value=csr_read_data;

/****************************************************************************************
module实例化
****************************************************************************************/
/*寄存器文件*/
core_id_reg_file core_id_reg_file_inst0(
  .clk          (clk                    ),
  .read_0_addr  (reg_file_read_0_addr   ),
  .read_0_data  (reg_file_read_0_data   ),
  .read_0_en    (reg_file_read_0_en     ),
  .read_1_addr  (reg_file_read_1_addr   ),
  .read_1_data  (reg_file_read_1_data   ),
  .read_1_en    (reg_file_read_1_en     ),
  .write_addr   (reg_file_write_addr    ),
  .write_data   (reg_file_write_data    ),
  .write_en     (reg_file_write_en      )
);
/*冲突检测模块*/
core_id_risk_detct core_id_risk_detct_inst0(
  .rs1          (risk_detct_rs1         ),
  .rs1_valid    (risk_detct_rs1_valid   ),
  .rs2          (risk_detct_rs2         ),
  .rs2_valid    (risk_detct_rs2_valid   ),
  .mem_write    (risk_detct_mem_write   ),
  .de_rd        (risk_detct_de_rd       ),
  .de_reg_write (risk_detct_de_reg_write),
  .de_mem_read  (risk_detct_de_mem_read ),
  .em_rd        (risk_detct_em_rd       ),
  .em_reg_write (risk_detct_em_reg_write),
  .em_mem_read  (risk_detct_em_mem_read ),
  .insert_nop   (risk_detct_insert_nop  )
);
/*指令解析*/
core_id_istr_dc core_id_istr_dc_inst0(
  .istr                (istr                ),
  .istr_dc_info        (istr_dc_info        )
);
/*获取alu操作码*/
core_id_istr_alu_dc core_id_istr_alu_dc_inst0(
  .istr_dc_info        (istr_dc_info        ),
  .istr_alu_dc_info    (istr_alu_dc_info    )
);
/*压缩指令转32bit指令*/
istr_c2i istr_c2i_inst(
  .istr_c(fd_istr[15:0]),
  .istr_i(istr_from_c)
);

/****************************************************************************************
仿真时检查
****************************************************************************************/
always @(posedge clk) begin
  if((istr[1:0]!=2'd3)&&fd_valid) begin
    $display("instruction ignore!");
  end
end

always @(posedge clk) begin
  if(fd_valid&&fd_ready) begin
    $display("id handle istr,pc=%x,istr=%x,type=%s",fd_pc,(fd_istr[1:0]==2'd3)?fd_istr:fd_istr[15:0],(fd_istr[1:0]==2'd3)?"i":"c");
  end
end

endmodule

