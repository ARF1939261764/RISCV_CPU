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
  input  logic[2:0]  de_mem_op,
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
  input  logic[1:0]  de_em_reg_data_mem_addr_sel,
  input  logic[1:0]  de_em_csr_data_mem_data_sel,
  /*EX/MEM级寄存器数据*/
  output logic       em_valid,
  output logic       em_start_handle,
  input  logic       em_ready,
  output logic[31:0] em_reg_data_mem_addr,
  output logic[31:0] em_csr_data_mem_data,
  output logic       em_mem_read,
  output logic       em_mem_write,
  output logic[2:0]  em_mem_op_type,
  output logic[4:0]  em_rd,
  output logic       em_reg_write,
  output logic[11:0] em_csr,
  output logic       em_csr_write,
  /*MA/WB级寄存器数据*/
  input  logic       mw_valid,
  input  logic[4:0]  mw_rd,
  input  logic       mw_reg_write,
  input  logic[31:0] mw_reg_write_data,
  input  logic       mw_mem_data_valid,
  input  logic[11:0] mw_csr,
  input  logic       mw_csr_write,
  input  logic[31:0] mw_csr_data,
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
logic[1:0]  alu_in1_sel;
logic[31:0] alu_in1_in[2:0];

logic[31:0] alu_in2;
logic[1:0]  alu_in2_sel;
logic[31:0] alu_in2_in[2:0];

logic[31:0] rs1_value;
logic[1:0]  rs1_sel;
logic[31:0] rs1_in[2:0];

logic[31:0] rs2_value;
logic[1:0]  rs2_sel;
logic[31:0] rs2_in[2:0];

logic[31:0] csr_value;
logic[1:0]  csr_sel;
logic[31:0] csr_in[2:0];

logic[31:0] csr_data_mem_data;
logic[1:0]  csr_data_mem_data_sel;
logic[31:0] csr_data_mem_data_in[2:0];

logic[31:0] reg_data_mem_addr;
logic[1:0]  reg_data_mem_addr_sel;
logic[31:0] reg_data_mem_addr_in[3:0];

logic       start_handle;
logic[31:0] pc_add;
/**************************************************************
选择rs1,rs2,csr的数据源
**************************************************************/
assign rs1_in[0]=de_rs1_value;
assign rs1_in[1]=em_reg_data_mem_addr;
assign rs1_in[2]=mw_reg_write_data;

assign rs2_in[0]=de_rs2_value;
assign rs2_in[1]=em_reg_data_mem_addr;
assign rs2_in[2]=mw_reg_write_data;

assign csr_in[0]=de_csr_value;
assign csr_in[1]=em_csr_data_mem_data;
assign csr_in[2]=mw_csr_data;

assign reg_data_mem_addr_in[0]=alu_out;
assign reg_data_mem_addr_in[1]=de_imm;
assign reg_data_mem_addr_in[2]=csr_value;
assign reg_data_mem_addr_in[3]=pc_add;
assign reg_data_mem_addr_sel  =de_em_reg_data_mem_addr_sel;

assign csr_data_mem_data_in[0]=alu_out;
assign csr_data_mem_data_in[1]=rs1_value;
assign csr_data_mem_data_in[2]=rs2_value;
assign csr_data_mem_data_sel=de_em_csr_data_mem_data_sel;

assign alu_in1_in[0]=rs1_value;
assign alu_in1_in[1]=de_zimm;
assign alu_in1_in[2]=de_pc;
assign alu_in1_sel=de_alu_in_1_sel;

assign alu_in2_in[0]=rs2_value;
assign alu_in2_in[1]=de_imm;
assign alu_in2_in[2]=de_csr_value;
assign alu_in2_sel=de_alu_in_2_sel;

/**************************************************************
连线
**************************************************************/
assign alu_op                = de_alu_op;
assign alu_op_valid          = de_valid;
assign pc_add                = de_pc+(de_istr_width?3'd4:3'd2);
assign de_ready              = alu_op_ready&&em_ready;

/*************************************************************
更新em寄存器
*************************************************************/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    em_valid             <= 1'd0;
    em_start_handle      <= 1'd0;
    em_reg_data_mem_addr <= 1'd0;
    em_csr_data_mem_data <= 1'd0;
    em_mem_read          <= 1'd0;
    em_mem_write         <= 1'd0;
    em_mem_op_type       <= 1'd0;
    em_rd                <= 1'd0;
    em_reg_write         <= 1'd0;
    em_csr               <= 1'd0;
    em_csr_write         <= 1'd0;
  end
  else begin
    if(!em_valid||em_ready) begin
      em_valid             <= de_valid&&alu_op_ready;
      em_start_handle      <= 1'd1;
      em_reg_data_mem_addr <= reg_data_mem_addr;
      em_csr_data_mem_data <= csr_data_mem_data;
      em_mem_read          <= de_mem_read;
      em_mem_write         <= de_mem_write;
      em_mem_op_type       <= de_mem_op;
      em_rd                <= de_rd;
      em_reg_write         <= de_reg_write;
      em_csr               <= de_csr;
      em_csr_write         <= de_csr_write;
    end
    else begin
      em_start_handle<=1'd0;
    end
  end
end

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
  .de_valid               (de_valid               ),
  .de_rs1                 (de_rs1                 ),
  .de_rs1_valid           (de_rs1_valid           ),
  .de_rs2                 (de_rs2                 ),
  .de_rs2_valid           (de_rs2_valid           ),
  .de_csr                 (de_csr                 ),
  .de_csr_valid           (de_csr_valid           ),
  .em_valid               (em_valid               ),
  .em_rd                  (em_rd                  ),
  .em_reg_write           (em_reg_write           ),
  .em_csr                 (em_csr                 ),
  .em_csr_write           (em_csr_write           ),
  .mw_valid               (mw_valid               ),
  .mw_rd                  (mw_rd                  ),
  .mw_reg_write           (mw_reg_write           ),
  .mw_mem_data_valid      (mw_mem_data_valid      ),
  .mw_csr                 (mw_csr                 ),
  .mw_csr_write           (mw_csr_write           ),
  .rs1_sel                (rs1_sel                ),
  .rs2_sel                (rs2_sel                ),
  .csr_sel                (csr_sel                ),
  .de_start_handle        (de_start_handle        ),
  .start_handle           (start_handle           )
);

/*多路复用器*/
mux_n21 #(
  .WIDTH(32 ),
  .NUM  (3  )
)
mux_inst0_rs1_mux(
  .sel(rs1_sel  ),
  .in (rs1_in   ),
  .out(rs1_value)
);
/*多路复用器*/
mux_n21 #(
  .WIDTH(32 ),
  .NUM  (3  )
)
mux_inst1_rs2_mux(
  .sel(rs2_sel  ),
  .in (rs2_in   ),
  .out(rs2_value)
);

mux_n21 #(
  .WIDTH(32 ),
  .NUM  (3  )
)
mux_inst2_csr_mux(
  .sel(csr_sel  ),
  .in (csr_in   ),
  .out(csr_value)
);

mux_n21 #(
  .WIDTH(32 ),
  .NUM  (4  )
)
mux_inst3_reg_data_mem_addr_mux(
  .sel(reg_data_mem_addr_sel  ),
  .in (reg_data_mem_addr_in   ),
  .out(reg_data_mem_addr      )
);

mux_n21 #(
  .WIDTH(32 ),
  .NUM  (3  )
)
mux_inst4_csr_data_mem_data_mux(
  .sel(csr_data_mem_data_sel  ),
  .in (csr_data_mem_data_in   ),
  .out(csr_data_mem_data      )
);

mux_n21 #(
  .WIDTH(32 ),
  .NUM  (3  )
)
mux_inst5_alu_in1_mux(
  .sel(alu_in1_sel  ),
  .in (alu_in1_in   ),
  .out(alu_in1      )
);

mux_n21 #(
  .WIDTH(32 ),
  .NUM  (3  )
)
mux_inst6_alu_in2_mux(
  .sel(alu_in2_sel  ),
  .in (alu_in2_in   ),
  .out(alu_in2      )
);

endmodule

