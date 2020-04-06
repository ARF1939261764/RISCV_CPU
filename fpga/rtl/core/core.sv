module core(
  input logic       clk,
  input logic       rest,
  i_avl_bus.master  avl_m0_istr,
  i_avl_bus.master  avl_m1_data
);

logic       fd_valid;
logic       fd_ready;
logic[31:0] fd_istr;
logic[31:0] fd_pc;
logic       fd_jump;
logic       fd_istr_width;

logic       de_valid;
logic       de_start_handle;
logic       de_ready;
logic[3:0]  de_alu_op;
logic[31:0] de_rs1_value;
logic[31:0] de_csr_value;
logic[4:0]  de_zimm;
logic[31:0] de_pc;
logic[31:0] de_rs2_value;
logic[31:0] de_imm; 
logic[4:0]  de_rd;
logic       de_reg_write;
logic       de_csr_write;
logic       de_mem_write;
logic       de_mem_read;
logic       de_mem_op;
logic       de_istr_width;
logic       de_is_br;
logic[3:0]  de_br_op;
logic       de_jump; 
logic[11:0] de_csr;
logic       de_csr_valid;
logic[4:0]  de_rs1;
logic[4:0]  de_rs2;
logic       de_rs1_valid;
logic       de_rs2_valid;
logic[1:0]  de_alu_in_1_sel;
logic[1:0]  de_alu_in_2_sel;
logic[1:0]  de_em_reg_data_mem_addr_sel;
logic[1:0]  de_em_csr_data_mem_data_sel;

logic       em_valid;
logic       em_start_handle;
logic       em_ready;
logic[31:0] em_reg_data_mem_addr;
logic[31:0] em_csr_data_mem_data;
logic       em_mem_read;
logic       em_mem_write;
logic[1:0]  em_mem_op_type;
logic[4:0]  em_rd;
logic       em_reg_write;
logic[11:0] em_csr;
logic       em_csr_write;

logic       mw_valid;
logic       mw_ready;
logic[31:0] mw_reg_data;
logic[31:0] mw_mem_data;
logic       mw_mem_data_valid;
logic[31:0] mw_csr_data;
logic[4:0]  mw_rd;
logic       mw_reg_write;
logic       mw_reg_write_sel;
logic[11:0] mw_csr;
logic       mw_csr_write;

logic       wb_valid;
logic       wb_ready;
logic[31:0] wb_reg_data;
logic[4:0]  wb_rd;
logic       wb_reg_write;
logic[31:0] wb_csr_data;
logic[11:0] wb_csr;
logic       wb_csr_write;




core_if #(
  .REST_ADDR(0)
)
core_if_inst0(
  .clk                        (clk                          ),
  .rest                       (rest                         ),
  .avl_m0                     (avl_m0_istr                  ),
  .csr_mepc                   (1'd0                         ),
  .jump_addr                  (1'd0                         ),
  .jump_en                    (1'd0                         ),
  .flush_en                   (1'd0                         ),
  .bp_istr                    (                             ),
  .bp_pc                      (                             ),
  .bp_jump_addr               (1'd0                         ),
  .bp_jump_en                 (1'd0                         ),
  .fd_valid                   (fd_valid                     ),
  .fd_ready                   (fd_ready                     ),
  .fd_istr                    (fd_istr                      ),
  .fd_pc                      (fd_pc                        ),
  .fd_jump                    (fd_jump                      ),
  .ctr_stop                   (1'd0                         )
);

core_id core_id_inst0(
  .clk                        (clk                          ),
  .rest                       (rest                         ),
  .fd_valid                   (fd_valid                     ),
  .fd_ready                   (fd_ready                     ),
  .fd_istr                    (fd_istr                      ),
  .fd_pc                      (fd_pc                        ),
  .fd_jump                    (fd_jump                      ),
  .de_valid                   (de_valid                     ),
  .de_start_handle            (de_start_handle              ),
  .de_ready                   (de_ready                     ),
  .de_alu_op                  (de_alu_op                    ),
  .de_rs1_value               (de_rs1_value                 ),
  .de_csr_value               (de_csr_value                 ),
  .de_zimm                    (de_zimm                      ),
  .de_pc                      (de_pc                        ),
  .de_rs2_value               (de_rs2_value                 ),
  .de_imm                     (de_imm                       )  ,   
  .de_rd                      (de_rd                        ),
  .de_reg_write               (de_reg_write                 ),
  .de_csr_write               (de_csr_write                 ),
  .de_mem_write               (de_mem_write                 ),
  .de_mem_read                (de_mem_read                  ),
  .de_mem_op                  (de_mem_op                    ),
  .de_istr_width              (de_istr_width                ),
  .de_is_br                   (de_is_br                     ),      
  .de_br_op                   (de_br_op                     ),      
  .de_jump                    (de_jump                      ),      
  .de_csr                     (de_csr                       ),
  .de_csr_valid               (de_csr_valid                 ),
  .de_rs1                     (de_rs1                       ),
  .de_rs2                     (de_rs2                       ),
  .de_rs1_valid               (de_rs1_valid                 ),
  .de_rs2_valid               (de_rs2_valid                 ),
  .de_alu_in_1_sel            (de_alu_in_1_sel              ),
  .de_alu_in_2_sel            (de_alu_in_2_sel              ),
  .de_em_reg_data_mem_addr_sel(de_em_reg_data_mem_addr_sel  ),
  .de_em_csr_data_mem_data_sel(de_em_csr_data_mem_data_sel  ),
  .wb_valid                   (wb_valid                     ),
  .wb_ready                   (wb_ready                     ),
  .wb_reg_data                (wb_reg_data                  ),
  .wb_rd                      (wb_rd                        ),
  .wb_reg_write               (wb_reg_write                 ),
  .wb_csr_data                (wb_csr_data                  ),
  .wb_csr                     (wb_csr                       ),
  .wb_csr_write               (wb_csr_write                 ),
  .ex_flush_en                (1'd0                         ),
  .csr_read                   (                             ),
  .csr_read_addr              (                             ),
  .csr_read_data              (                             ),
  .csr_write                  (                             ),
  .csr_write_addr             (                             ),
  .csr_write_data             (                             ),
  .em_rd                      (                             ),
  .em_reg_write               (                             ),
  .em_mem_read                (                             )
);

core_ex core_ex_inst0(
  .clk                        (clk                        ),
  .rest                       (rest                       ),
  .de_valid                   (de_valid                   ),
  .de_start_handle            (de_start_handle            ),
  .de_ready                   (de_ready                   ),
  .de_alu_op                  (de_alu_op                  ),
  .de_rs1_value               (de_rs1_value               ),
  .de_csr_value               (de_csr_value               ),
  .de_zimm                    (de_zimm                    ),
  .de_pc                      (de_pc                      ),
  .de_rs2_value               (de_rs2_value               ),
  .de_imm                     (de_imm                     ),
  .de_rd                      (de_rd                      ),
  .de_reg_write               (de_reg_write               ),
  .de_csr_write               (de_csr_write               ),
  .de_mem_write               (de_mem_write               ),
  .de_mem_read                (de_mem_read                ),
  .de_mem_op                  (de_mem_op                  ),
  .de_istr_width              (de_istr_width              ),
  .de_is_br                   (de_is_br                   ),     
  .de_br_op                   (de_br_op                   ),    
  .de_jump                    (de_jump                    ),      
  .de_csr                     (de_csr                     ),
  .de_csr_valid               (de_csr_valid               ),
  .de_rs1                     (de_rs1                     ),
  .de_rs2                     (de_rs2                     ),
  .de_rs1_valid               (de_rs1_valid               ),
  .de_rs2_valid               (de_rs2_valid               ),
  .de_alu_in_1_sel            (de_alu_in_1_sel            ),
  .de_alu_in_2_sel            (de_alu_in_2_sel            ),
  .de_em_reg_data_mem_addr_sel(de_em_reg_data_mem_addr_sel),
  .de_em_csr_data_mem_data_sel(de_em_csr_data_mem_data_sel),
  .em_valid                   (em_valid                   ),
  .em_start_handle            (em_start_handle            ),
  .em_ready                   (em_ready                   ),
  .em_reg_data_mem_addr       (em_reg_data_mem_addr       ),
  .em_csr_data_mem_data       (em_csr_data_mem_data       ),
  .em_mem_read                (em_mem_read                ),
  .em_mem_write               (em_mem_write               ),
  .em_mem_op_type             (em_mem_op_type             ),
  .em_rd                      (em_rd                      ),
  .em_reg_write               (em_reg_write               ),
  .em_csr                     (em_csr                     ),
  .em_csr_write               (em_csr_write               ),
  .mw_rd                      (),
  .mw_reg_write               (),
  .mw_reg_write_data          (),
  .mw_mem_data_valid          (),
  .mw_csr                     (),
  .mw_csr_write               (),
  .mw_csr_data                (),
  .exception_valid            (1'd0                       ),
  .exception_ready            (                           ),
  .exception_cause            (1'd0                       ),
  .exception_csr_mtvec        (1'd0                       ),
  .pc                         (                           ),
  .next_pc                    (                           ),
  .istr                       (                           ),
  .jump_en                    (                           ),
  .jump_addr                  (                           ),
  .flush_en                   (                           ),
  .bp_pc                      (                           ),
  .bp_istr                    (                           ),
  .bp_jump_pc                 (                           ),
  .bp_jump_en                 (                           ),
  .bp_is_exception            (                           )
);

core_ma core_ma_inst0(
  .clk                        (clk                        ),
  .rest                       (rest                       ),
  .em_valid                   (em_valid                   ),
  .em_start_handle            (em_start_handle            ),
  .em_ready                   (em_ready                   ),
  .em_reg_data_mem_addr       (em_reg_data_mem_addr       ),
  .em_csr_data_mem_data       (em_csr_data_mem_data       ),
  .em_mem_read                (em_mem_read                ),
  .em_mem_write               (em_mem_write               ),
  .em_mem_op_type             (em_mem_op_type             ),
  .em_rd                      (em_rd                      ),
  .em_reg_write               (em_reg_write               ),
  .em_csr                     (em_csr                     ),
  .em_csr_write               (em_csr_write               ),
  .mw_valid                   (mw_valid                   ),
  .mw_ready                   (mw_ready                   ),
  .mw_reg_data                (mw_reg_data                ),
  .mw_mem_data                (mw_mem_data                ),
  .mw_mem_data_valid          (mw_mem_data_valid          ),
  .mw_csr_data                (mw_csr_data                ),
  .mw_rd                      (mw_rd                      ),
  .mw_reg_write               (mw_reg_write               ),
  .mw_reg_write_sel           (mw_reg_write_sel           ),
  .mw_csr                     (mw_csr                     ),
  .mw_csr_write               (mw_csr_write               ),
  .avl_m0                     (avl_m1_data                )
);

core_wb core_wb_inst0(
  .clk                        (clk                        ),
  .rest                       (rest                       ),
  .mw_valid                   (mw_valid                   ),
  .mw_ready                   (mw_ready                   ),
  .mw_reg_data                (mw_reg_data                ),
  .mw_mem_data                (mw_mem_data                ),
  .mw_csr_data                (mw_csr_data                ),
  .mw_rd                      (mw_rd                      ),
  .mw_reg_write               (mw_reg_write               ),
  .mw_reg_write_sel           (mw_reg_write_sel           ),
  .mw_csr                     (mw_csr                     ),
  .mw_csr_write               (mw_csr_write               ),
  .wb_valid                   (wb_valid                   ),
  .wb_ready                   (wb_ready                   ),
  .wb_reg_data                (wb_reg_data                ),
  .wb_rd                      (wb_rd                      ),
  .wb_reg_write               (wb_reg_write               ),
  .wb_csr_data                (wb_csr_data                ),
  .wb_csr                     (wb_csr                     ),
  .wb_csr_write               (wb_csr_write               )
);

endmodule
