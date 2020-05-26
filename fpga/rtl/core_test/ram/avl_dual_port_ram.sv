module avl_dual_port_ram #(
  parameter        DEPTH = 64*1024
)(
  input clk,
  input rest,
  i_avl_bus.slave avl_s0,
  i_avl_bus.slave avl_s1
);

ram ram_inst0(
	.address_a(avl_s0.address[31:2]),
	.address_b(avl_s1.address[31:2]),
	.byteena_a(avl_s0.byte_en			 ),
	.byteena_b(avl_s1.byte_en			 ),
	.clock		(clk								 ),
	.data_a		(avl_s0.write_data	 ),
	.data_b		(avl_s1.write_data	 ),
	.wren_a		(avl_s0.write				 ),
	.wren_b		(avl_s1.write				 ),
	.q_a			(avl_s0.read_data		 ),
	.q_b			(avl_s1.read_data		 )
);

assign avl_s0.request_ready = 1;
assign avl_s1.request_ready = 1;

always @(posedge clk) begin
  avl_s0.read_data_valid = avl_s0.read;
  avl_s1.read_data_valid = avl_s1.read;
end

endmodule
