package avl_bus_type;

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

typedef struct
{
  int addr_block;
  int field_len;
}avl_addr_map_tab_t;


endpackage
