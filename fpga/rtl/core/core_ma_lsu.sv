`include "core_define.sv"

module core_ma_lsu (
  input  logic       clk,
  input  logic       rest,
  input  logic       mw_ready,
  output logic       lsu_cmd_send_done,
  input  logic[31:0] mem_addr,
  input  logic[31:0] mem_data,
  input  logic       mem_read,
  input  logic       mem_write,
  input  logic[2:0]  mem_op_type,
  output logic[31:0] mem_read_data,
  output logic       mem_read_data_valid,
  i_avl_bus.master   avl_m0
);

/*变量*/
logic[2:0]  data_len;
logic       mw_generate_addr_data_mem_read;
logic[31:0] mw_generate_addr_data_mem_addr;
logic[2:0]  mw_generate_addr_data_mem_op_type;
logic[2:0]  mw_data_len;
logic       mem_op_cmd_send_done;

assign data_len  =  {3{(mem_op_type==`MEM_OP_B)||(mem_op_type==`MEM_OP_BU)}}&3'd1|
                    {3{(mem_op_type==`MEM_OP_H)||(mem_op_type==`MEM_OP_HU)}}&3'd2|
                    {3{mem_op_type==`MEM_OP_W}}&3'd4;
assign lsu_cmd_send_done = mem_op_cmd_send_done;
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    mw_generate_addr_data_mem_read<=1'd0;
  end
  else begin
    if(!mw_generate_addr_data_mem_read||mem_read_data_valid) begin
      mw_generate_addr_data_mem_read    <=  mem_read;
      mw_generate_addr_data_mem_addr    <=  mem_addr;
      mw_generate_addr_data_mem_op_type <=  mem_op_type;
      mw_data_len<=data_len;
    end
  end
end
assign avl_m0.resp_ready = 1'd1;

/*地址生成*/
core_ma_lsu_generate_addr core_ma_lsu_generate_addr_inst0(
  .clk                          (clk                               ),
  .rest                         (rest                              ),
  .mw_ready                     (mw_ready                          ),
  .mem_addr                     (mem_addr                          ),
  .mem_data                     (mem_data                          ),
  .mem_read                     (mem_read                          ),
  .mem_write                    (mem_write                         ),
  .mem_op_type                  (mem_op_type                       ),
  .mem_op_data_len              (data_len                          ),
  .mem_op_cmd_send_done         (mem_op_cmd_send_done              ),
  .avl_m0_address               (avl_m0.address                    ),
  .avl_m0_read                  (avl_m0.read                       ),
  .avl_m0_write                 (avl_m0.write                      ),
  .avl_m0_byte_en               (avl_m0.byte_en                    ),
  .avl_m0_write_data            (avl_m0.write_data                 ),
  .avl_m0_begin_burst_transfer  (avl_m0.begin_burst_transfer       ),
  .avl_m0_burst_count           (avl_m0.burst_count                ),
  .avl_m0_request_ready         (avl_m0.request_ready              )
);

core_ma_lsu_generate_data core_ma_lsu_generate_data_inst0(
  .clk                          (clk                               ),
  .rest                         (rest                              ),
  .mem_read                     (mw_generate_addr_data_mem_read    ),
  .mem_addr                     (mw_generate_addr_data_mem_addr    ),
  .mem_op_type                  (mw_generate_addr_data_mem_op_type ),
  .mem_op_data_len              (mw_data_len                       ),
  .mem_read_data                (mem_read_data                     ),
  .mem_read_data_valid          (mem_read_data_valid               ),
  .avl_m0_read_data             (avl_m0.read_data                  ),
  .avl_m0_read_data_valid       (avl_m0.read_data_valid            )
);
endmodule

