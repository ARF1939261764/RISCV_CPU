module avl_bus_nm2s_controller #(
  parameter MASTER_NUM = 8
)(
  i_avl_bus.slave  alv_s[MASTER_NUM-1:0],  /*外面的主接口会接到这里，所以这里应该为从接口*/
  i_avl_bus.master avl_m
);

typedef struct
{
  logic[31:0] address;
  logic[3:0]  byte_en;
  logic       read;
  logic       write;
  logic[31:0] write_data;
  logic       begin_burst_transfer;
  logic[7:0]  burst_count;
}avl_cmd_t;

endmodule
