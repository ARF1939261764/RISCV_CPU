module core(
  logic clk,
  logic rest,
  
);
/*主机接口,访问总线*/
i_avl_bus     if_avl_m0,
/*跳转，冲刷控制*/
logic[31:0]   if_csr_mepc,
logic[31:0]   if_jump_addr,
logic         if_jump_en,
logic         if_flush_en,
/*分支预测接口*/
logic[31:0]   if_bp_istr,
logic[31:0]   if_bp_pc,
logic[31:0]   if_bp_jump_addr,
logic         if_bp_jump_en,
/*指令交付给下一级*/
logic[31:0]   if_dely_istr,
logic[31:0]   if_dely_pc,
logic         if_dely_valid,
logic         if_dely_jump,
logic         if_dely_ready,
/*其它控制信号*/
logic         if_ctr_stop            /*停止cpu*/

core_if #(
  .REST_ADDR(32'd0)
)
core_if_inst0(
  .clk          (if_clk          ),
  .rest         (if_rest         ),
  .avl_m0       (if_avl_m0       ),
  .csr_mepc     (if_csr_mepc     ),
  .jump_addr    (if_jump_addr    ),
  .jump_en      (if_jump_en      ),
  .flush_en     (if_flush_en     ),
  .bp_istr      (if_bp_istr      ),
  .bp_pc        (if_bp_pc        ),
  .bp_jump_addr (if_bp_jump_addr ),
  .bp_jump_en   (if_bp_jump_en   ),
  .dely_istr    (if_dely_istr    ),
  .dely_pc      (if_dely_pc      ),
  .dely_valid   (if_dely_valid   ),
  .dely_jump    (if_dely_jump    ),
  .dely_ready   (if_dely_ready   ),
  .ctr_stop     (if_ctr_stop     )
);


endmodule
