module avl_bus_default_slave(
  i_avl_bus.slave avl_s
);

assign avl_m.request_ready   ='d0;
assign avl_m.read_data       ='d0;
assign avl_m.read_data_valid ='d0;

endmodule
