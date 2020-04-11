`include "core_define.sv"

module core_ma_lsu (
  input  logic       clk,
  input  logic       rest,
  output logic       lsu_ready,
  input  logic[31:0] mem_addr,
  input  logic[31:0] mem_data,
  input  logic       mem_read,
  input  logic       mem_write,
  input  logic[2:0]  mem_op_type,
  output logic[31:0] mem_read_data,
  output logic       mem_read_data_valid,
  i_avl_bus.master   avl_m0
);
/*参数*/
localparam  MEM_OP_CMD_FIFO_DEPTH=2,
            MEM_OP_CMD_FIFO_WIDTH=$bits({
              mem_addr,
              mem_data,
              mem_read,
              mem_write,
              mem_op_type
            });
/*变量*/
logic[2:0]  data_len;

/*mem_op fifo*/
logic                            mem_op_cmd_fifofull;
logic                            mem_op_cmd_fifoempty;
logic                            mem_op_cmd_fifohalf;
logic                            mem_op_cmd_fifowrite;
logic                            mem_op_cmd_fiforead;
logic[MEM_OP_CMD_FIFO_WIDTH-1:0] mem_op_cmd_fifowriteData;
logic[MEM_OP_CMD_FIFO_WIDTH-1:0] mem_op_cmd_fiforeadData;

/*生成地址模块的端口*/
logic[31:0] generate_addr_data_mem_addr;
logic[31:0] generate_addr_data_mem_data;
logic       generate_addr_data_mem_read;
logic       generate_addr_data_mem_write;
logic[2:0]  generate_addr_data_mem_op_type;
logic       generate_addr_data_mem_op_cmd_send_done;
/*mem fifo端口赋值*/
assign      mem_op_cmd_fifowrite=(mem_read||mem_write)&&!mem_op_cmd_fifoempty;
assign      mem_op_cmd_fiforead =generate_addr_data_mem_op_cmd_send_done;
assign      mem_op_cmd_fifowriteData={
              mem_addr,
              mem_data,
              mem_read,
              mem_write,
              mem_op_type
            };
assign      {
              generate_addr_data_mem_addr,
              generate_addr_data_mem_data,
              generate_addr_data_mem_read,
              generate_addr_data_mem_write,
              generate_addr_data_mem_op_type
            }=mem_op_cmd_fiforeadData;

assign data_len  =  {3{(mem_op_type==`MEM_OP_B)||(mem_op_type==`MEM_OP_BU)}}&3'd1|
                    {3{(mem_op_type==`MEM_OP_H)||(mem_op_type==`MEM_OP_HU)}}&3'd2|
                    {3{mem_op_type==`MEM_OP_W}}&3'd4;
assign lsu_ready =  mem_read_data_valid;


logic       mw_generate_addr_data_mem_read;
logic[31:0] mw_generate_addr_data_mem_addr;
logic[2:0]  mw_generate_addr_data_mem_op_type;
logic[2:0]  mw_data_len;

always @(posedge clk or negedge rest) begin
  if(!rest) begin
    mw_generate_addr_data_mem_read<=1'd0;
  end
  else begin
    if(!mw_generate_addr_data_mem_read||mem_read_data_valid) begin
      mw_generate_addr_data_mem_read<=generate_addr_data_mem_read;
      mw_generate_addr_data_mem_addr<=generate_addr_data_mem_addr;
      mw_generate_addr_data_mem_op_type<=generate_addr_data_mem_op_type;
      mw_data_len<=data_len;
    end
  end
end

/*fifo*/
fifo_sync_bypass #(
  .DEPTH(MEM_OP_CMD_FIFO_DEPTH),
  .WIDTH(MEM_OP_CMD_FIFO_WIDTH)
)
fifo_sync_bypass_inst0_mem_op_cmd_fifo(
  .clk      (clk                      ),
  .rest     (rest                     ),
  .flush    (1'd0                     ),
  .full     (mem_op_cmd_fifofull      ),
  .empty    (mem_op_cmd_fifoempty     ),
  .half     (mem_op_cmd_fifohalf      ),
  .write    (mem_op_cmd_fifowrite     ),
  .read     (mem_op_cmd_fiforead      ),
  .writeData(mem_op_cmd_fifowriteData ),
  .readData (mem_op_cmd_fiforeadData  ),
  .allData  (/*none*/                 )
);
/*地址生成*/
core_ma_lsu_generate_addr core_ma_lsu_generate_addr_inst0(
  .clk                          (clk                                     ),
  .rest                         (rest                                    ),
  .mem_addr                     (generate_addr_data_mem_addr             ),
  .mem_data                     (generate_addr_data_mem_data             ),
  .mem_read                     (generate_addr_data_mem_read             ),
  .mem_write                    (generate_addr_data_mem_write            ),
  .mem_op_type                  (generate_addr_data_mem_op_type          ),
  .mem_op_data_len              (data_len                                ),
  .mem_op_cmd_send_done         (generate_addr_data_mem_op_cmd_send_done ),
  .avl_m0_address               (avl_m0.address                          ),
  .avl_m0_read                  (avl_m0.read                             ),
  .avl_m0_write                 (avl_m0.write                            ),
  .avl_m0_byte_en               (avl_m0.byte_en                          ),
  .avl_m0_write_data            (avl_m0.write_data                       ),
  .avl_m0_begin_burst_transfer  (avl_m0.begin_burst_transfer             ),
  .avl_m0_burst_count           (avl_m0.burst_count                      ),
  .avl_m0_request_ready         (avl_m0.request_ready                    )
);

core_ma_lsu_generate_data core_ma_lsu_generate_data_inst0(
  .clk                          (clk                                     ),
  .rest                         (rest                                    ),
  .mem_read                     (mw_generate_addr_data_mem_read          ),
  .mem_addr                     (mw_generate_addr_data_mem_addr          ),
  .mem_op_type                  (mw_generate_addr_data_mem_op_type       ),
  .mem_op_data_len              (mw_data_len                             ),
  .mem_read_data                (mem_read_data                           ),
  .mem_read_data_valid          (mem_read_data_valid                     ),
  .avl_m0_read_data             (avl_m0.read_data                        ),
  .avl_m0_read_data_valid       (avl_m0.read_data_valid                  )
);
endmodule

