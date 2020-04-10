`include "core_define.sv"
module core_ma_lsu_generate_addr(
  input  logic       clk,
  input  logic       rest,
  input  logic[31:0] mem_addr,
  input  logic[31:0] mem_data,
  input  logic       mem_read,
  input  logic       mem_write,
  input  logic[2:0]  mem_op_type,
  input  logic[2:0]  mem_op_data_len,
  output logic       mem_op_cmd_send_done,
  output logic[31:0] avl_m0_address,
  output logic       avl_m0_read,
  output logic       avl_m0_write,
  output logic[3:0]  avl_m0_byte_en,
  output logic[31:0] avl_m0_write_data,
  output logic       avl_m0_begin_burst_transfer,
  output logic[7:0]  avl_m0_burst_count,
  input  logic       avl_m0_request_ready
);
logic       cmd_send_success[1:0];
logic       sel;
logic[31:0] addr[1:0];
logic       addr_valid[1:0];
logic[2:0]  data_len;
logic[3:0]  write_byte_en;

logic[31:0] write_data[1:0];
logic[3:0]  byte_en[1:0];
logic[31:0] data_0_mux_in[3:0];
logic[1:0]  data_0_mux_sel;
logic[31:0] data_1_mux_in[2:0];
logic[1:0]  data_1_mux_sel;
logic[31:0] byte_en_0_mux_in[3:0];
logic[1:0]  byte_en_0_mux_sel;
logic[31:0] byte_en_1_mux_in[2:0];
logic[1:0]  byte_en_1_mux_sel;

assign data_len      =  mem_op_data_len;

assign addr[0]       =  {mem_addr[31:2],2'd0};
assign addr[1]       =  addr[0]+4;
assign addr_valid[0] =  1'd1;
assign addr_valid[1] =  (({1'd0,mem_addr[1:0]}+data_len)>3'd4)?1'd1:1'd0;

assign data_0_mux_in[0] = mem_data;
assign data_0_mux_in[1] = {mem_data[23:0], 8'd0};
assign data_0_mux_in[2] = {mem_data[15:0],16'd0};
assign data_0_mux_in[3] = {mem_data[7:0] ,24'd0};
assign data_0_mux_sel   = mem_addr[1:0];

assign data_1_mux_in[0] = { 8'd0,mem_data[31: 8]};
assign data_1_mux_in[1] = {16'd0,mem_data[31:16]};
assign data_1_mux_in[2] = {24'd0,mem_data[31:24]};
assign data_1_mux_sel   = 2'd3-mem_addr[1:0];

assign byte_en_0_mux_in[0] = write_byte_en;
assign byte_en_0_mux_in[1] = {write_byte_en[2:0],1'd0};
assign byte_en_0_mux_in[2] = {write_byte_en[1:0],2'd0};
assign byte_en_0_mux_in[3] = {write_byte_en[0:0],3'd0};
assign byte_en_0_mux_sel   = mem_addr[1:0];

assign byte_en_1_mux_in[0] = {1'd0,mem_data[3:1]};
assign byte_en_1_mux_in[1] = {2'd0,mem_data[3:2]};
assign byte_en_1_mux_in[2] = {3'd0,mem_data[3:3]};
assign byte_en_1_mux_sel   = 2'd3-mem_addr[1:0];

assign mem_op_cmd_send_done= (!addr_valid[0]||cmd_send_success[0])&&(!addr_valid[1]||cmd_send_success[1]);

always @(posedge clk or negedge rest) begin
  if(!rest) begin
    cmd_send_success[0]<=1'd0;
    cmd_send_success[1]<=1'd0;
  end
  else begin
    if(mem_op_cmd_send_done) begin
      cmd_send_success[0]<=1'd0;
      cmd_send_success[1]<=1'd0;
    end
    else if((avl_m0_read||avl_m0_write)&&avl_m0_request_ready) begin
      cmd_send_success[sel]<=1'd1;
    end
  end
end

assign sel=cmd_send_success[0];/*优先读第一个地址*/

assign write_byte_en                = {4{(data_len==3'd1)}}&4'b0001|
                                      {4{(data_len==3'd2)}}&4'b0011|
                                      {4{(data_len==3'd4)}}&4'b1111;
assign avl_m0_address               = addr[sel];
assign avl_m0_read                  = mem_read &&!mem_op_cmd_send_done;
assign avl_m0_write                 = mem_write&&!mem_op_cmd_send_done;
assign avl_m0_byte_en               = byte_en[sel];
assign avl_m0_write_data            = write_data[sel];
assign avl_m0_begin_burst_transfer  = 1'd0;
assign avl_m0_burst_count           = 1'd0;
/*data多路复用器*/
mux_n21 #(
  .WIDTH(32),
  .NUM  (4 )
)
mux_n21_inst0_data_0_mux(
  .sel(data_0_mux_sel),
  .in (data_0_mux_in ),
  .out(write_data[0] )
);
/*data多路复用器*/
mux_n21 #(
  .WIDTH(32),
  .NUM  (3 )
)
mux_n21_inst1_data_1_mux(
  .sel(data_1_mux_sel),
  .in (data_1_mux_in ),
  .out(write_data[1] )
);
/*byte_en多路复用器*/
mux_n21 #(
  .WIDTH(4),
  .NUM  (4)
)
mux_n21_inst2_byte_en_0_mux(
  .sel(byte_en_0_mux_sel),
  .in (byte_en_0_mux_in ),
  .out(byte_en[0]       )
);
/*byte_en多路复用器*/
mux_n21 #(
  .WIDTH(4),
  .NUM  (3)
)
mux_n21_inst3_byte_en_1_mux(
  .sel(byte_en_1_mux_sel),
  .in (byte_en_1_mux_in ),
  .out(byte_en[1]       )
);
endmodule
