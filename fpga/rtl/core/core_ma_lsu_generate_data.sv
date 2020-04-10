`include "core_define.sv"
module core_ma_lsu_generate_data (
  input  logic       clk,
  input  logic       rest,
  input  logic       mem_read,
  input  logic[31:0] mem_addr,
  input  logic[2:0]  mem_op_type,
  input  logic[2:0]  mem_op_data_len,
  output logic[31:0] mem_read_data,
  output logic       mem_read_data_valid,
  input  logic[31:0] avl_m0_read_data,
  input  logic       avl_m0_read_data_valid
);

logic addr_valid[1:0];
logic data_valid[1:0];
logic[31:0] data[1:0];
logic[31:0] data_buff;

logic[1:0]  read_data_mux_sel;
logic[31:0] read_data_mux_in[3:0];
logic[31:0] read_data;

assign addr_valid[0]=1'd1;
assign addr_valid[1]=(({1'd0,mem_addr[1:0]}+mem_op_data_len)>3'd4)?1'd1:1'd0;
assign data[0]=mem_read_data;
assign data[1]=data_buff;

assign read_data_mux_in[0]= data[0];
assign read_data_mux_in[1]= {data[1][ 7: 0],data[0][31: 8]};
assign read_data_mux_in[2]= {data[1][15: 8],data[0][31:16]};
assign read_data_mux_in[3]= {data[1][24:16],data[0][31:24]};

assign read_data_mux_sel  = mem_addr[1:0];

assign data_valid[0]=avl_m0_read_data_valid;
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    data_valid[1]<=1'd0;
  end
  else begin
    if(mem_read_data_valid) begin
      data_valid[1]<=1'd0;
    end
    else begin
      data_valid[1]<=data_valid[0];
    end
  end
end

always @(posedge clk) begin
  if(data_valid[0]) begin
    data_buff<=mem_read_data;
  end
end

assign mem_read_data_valid    = ((!addr_valid[0])||data_valid[0])&&
                                ((!addr_valid[1])||data_valid[1]);
assign mem_read_data          = {32{(mem_op_type==`MEM_OP_B )}}&{{24{read_data[ 7]}},read_data[ 7:0]}|
                                {32{(mem_op_type==`MEM_OP_BU)}}&{{24{1'd0         }},read_data[ 7:0]}|
                                {32{(mem_op_type==`MEM_OP_H )}}&{{16{read_data[15]}},read_data[15:0]}|
                                {32{(mem_op_type==`MEM_OP_HU)}}&{{16{1'd0         }},read_data[15:0]}|
                                {32{(mem_op_type==`MEM_OP_W )}}&read_data;

/*read data多路复用器*/
mux_n21 #(
  .WIDTH(32),
  .NUM  (4)
)
mux_n21_inst2_byte_en_0_mux(
  .sel(read_data_mux_sel),
  .in (read_data_mux_in ),
  .out(read_data        )
);

endmodule
