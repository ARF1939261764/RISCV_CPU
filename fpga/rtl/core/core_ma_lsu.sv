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
  output logic[31:0] mem_read_data_valid,
  i_avl_bus.master   avl_m0
);
/*参数*/
localparam  MEM_OP_CMD_FIFO_DEPTH=2,
            MEM_OP_CMD_FIFO_DEPTH=$bits(
              mem_addr,
              mem_data,
              mem_read,
              mem_write,
              mem_op_type
            );
/*变量*/
logic       mem_op_cmd_fifofull;
logic       mem_op_cmd_fifoempty;
logic       mem_op_cmd_fifohalf;
logic       mem_op_cmd_fifowrite;
logic       mem_op_cmd_fiforead;
logic[31:0] mem_op_cmd_fifowriteData;
logic[31:0] mem_op_cmd_fiforeadData; 

fifo_sync_bypass #(
  .DEPTH(MEM_OP_CMD_FIFO_DEPTH),
  .WIDTH(MEM_OP_CMD_FIFO_DEPTH)
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
  .allData  ('z                       )
);

endmodule

module core_ma_lsu_generate_addr(
  input  logic[31:0] mem_addr,
  input  logic[31:0] mem_data,
  input  logic       mem_read,
  input  logic       mem_write,
  input  logic[2:0]  mem_op_type,
  input  logic       mem_op_ready,
  output logic       mem_op_cmd_send_done,
  i_avl_bus.master   avl_m0
);
logic       cmd_send_success[1:0];
logic       sel;
logic[31:0] addr[1:0];
logic       addr_valid[1:0];
logic[2:0]  data_len;

assign data_len      =  {3{(mem_op_type==`MEM_OP_B)||(mem_op_type==`MEM_OP_BU)}}&3'd1|
                        {3{(mem_op_type==`MEM_OP_H)||(mem_op_type==`MEM_OP_HU)}}&3'd2|
                        {3{mem_op_type==`MEM_OP_W}}&3'd4;

assign addr[0]       = {mem_addr[31:2],2'd0};
assign addr[1]       = addr[0]+4;
assign addr_valid[0] = 1'd1;
assign addr_valid[1] = (({1'd0,mem_addr[1:0]}+data_len)>3'd4)?1'd1:1'd0;

always @(posedge clk or negedge rest) begin
  if(!rest) begin
    sel<=1'd0;
  end
  else begin
    if(mem_op_ready) begin
      cmd_send_success[0]<=1'd0;
      cmd_send_success[1]<=1'd0;
      sel<=1'd0;
    end
    else if((avl_m0.read||avl_m0.write)&&avl_m0.request_ready) begin
      cmd_send_success[sel]<=1'd1;
      sel++;
    end
  end
end

assign avl_m0.address               = addr[sel];
assign avl_m0.read                  = mem_read &&!mem_op_cmd_send_done;
assign avl_m0.write                 = mem_write&&!mem_op_cmd_send_done;



assign avl_m0.begin_burst_transfer  = 1'd0;
assign avl_m0.burst_count           = 1'd0;
/*data多路复用器*/
mux_n21 #(
  .WIDTH(32),
  .NUM  (4 )
)
mux_n21_inst0_data_mux(
  .sel(),
  .in (),
  .out()
);
/*byte_en多路复用器*/
mux_n21 #(
  .WIDTH(4),
  .NUM  (4)
)
mux_n21_inst0_byte_en_mux(
  .sel(),
  .in (),
  .out()
);
endmodule

module core_ma_lsu_generate_data (
  
);
  
endmodule
