module gpio (
  input logic     clk,
  input logic     rest,
  i_avl_bus.slave avl_s0,
  inout logic     io[31:0]
);

logic[31:0] reg_odr;
logic[31:0] reg_idr;
logic[31:0] reg_mode;

genvar i;
generate
  for(i=0;i<32;i++) begin:block_0
    assign io[i]=reg_mode[i]?reg_odr[i]:1'dz;
    assign reg_idr[i] = io[i];
  end
endgenerate

always @(posedge clk or negedge rest) begin
  if(!rest) begin
    reg_odr <=32'd0;
    reg_mode<=32'd0;
  end
  else begin
    if(avl_s0.write) begin
      if(avl_s0.address[3:2] == 2'd0) reg_odr<=avl_s0.write_data;
      if(avl_s0.address[3:2] == 2'd2) reg_mode<=avl_s0.write_data;
    end
    else begin
      if(avl_s0.read) begin
        case(avl_s0.address[3:2])
          2'd0:avl_s0.read_data<=reg_odr;
          2'd1:avl_s0.read_data<=reg_idr;
          2'd2:avl_s0.read_data<=reg_mode;
          default:begin end
        endcase
      end
    end
  end
end

always @(posedge clk) begin
  avl_s0.read_data_valid<=avl_s0.read;
end
assign avl_s0.request_ready = 1;

endmodule