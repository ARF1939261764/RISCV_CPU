`timescale 1ns/100ps
module avl_bus_monitor_sim_model #(
  parameter     MASTER_NUM                    = 8,
                SLAVE_NUM                     = 16,
            int ADDR_MAP_TAB_FIELD_LEN[31:0]  = '{32{32'd22}},
            int ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{32{1'd0}}
)(
  input                       clk,
  input                       rest,
  i_avl_bus.monitor           avl_mon[MASTER_NUM-1:0],
  output logic[31:0]          value[MASTER_NUM-1:0]
);
/********************************************************
变量
********************************************************/
typedef struct
{
  logic[31:0] addr;
  int master;
  int slave;
}read_cmd_t;

logic[3:0][7:0]           ram[SLAVE_NUM-1:0][];
read_cmd_t                read_cmd_queue[$];
logic[MASTER_NUM-1:0]     read_data_valid;
read_cmd_t                read_cmds[MASTER_NUM-1:0];
virtual i_avl_bus.monitor avl_vmon[MASTER_NUM-1:0];

generate
  genvar i;
  for(i=0;i<MASTER_NUM;i++) begin:block_init_vi
    assign avl_vmon[i]=avl_mon[i];
  end
endgenerate

/********************************************************
地址映射函数
********************************************************/
function int addr_map(logic[31:0] addr);
  int i;
  logic[31:0] addr0,addr1;
  for(i=0;i<SLAVE_NUM;i++) begin
    addr0=addr/(2**(32-ADDR_MAP_TAB_FIELD_LEN[i]));
    addr1=ADDR_MAP_TAB_ADDR_BLOCK[i]/(2**(32-ADDR_MAP_TAB_FIELD_LEN[i]));
    if(addr0==addr1) begin
      break;
    end
  end
  if(i==SLAVE_NUM) begin
    $error("Invalid address:%h",addr);
    $stop();
  end
  return i;
endfunction
/********************************************************
监控写操作
********************************************************/
always @(posedge clk or negedge rest) begin:block_0
  int i,j,index;
  if(!rest) begin
    for(i=0;i<SLAVE_NUM;i++) begin
      /*申请内存*/
      if(ram[i].size!=0) begin
        ram[i].delete();/*如果大小不为0,则清空后再申请*/
      end
      ram[i]=new[2**(32-ADDR_MAP_TAB_FIELD_LEN[i])/4];
      for(j=0;j<2**(32-ADDR_MAP_TAB_FIELD_LEN[i])/4;j++) begin
        ram[i][j]=0;
      end
    end
  end
  else begin
    for(i=0;i<MASTER_NUM;i++) begin
      if(avl_vmon[i].write&&avl_vmon[i].request_ready) begin
        /*发送写命令成功*/
        index=addr_map(avl_vmon[i].address);
        if(avl_vmon[i].byte_en[0]) ram[index][(avl_vmon[i].address-ADDR_MAP_TAB_ADDR_BLOCK[index])/4][0]=avl_vmon[i].write_data[ 7: 0];
        if(avl_vmon[i].byte_en[1]) ram[index][(avl_vmon[i].address-ADDR_MAP_TAB_ADDR_BLOCK[index])/4][1]=avl_vmon[i].write_data[15: 8];
        if(avl_vmon[i].byte_en[2]) ram[index][(avl_vmon[i].address-ADDR_MAP_TAB_ADDR_BLOCK[index])/4][2]=avl_vmon[i].write_data[23:16];
        if(avl_vmon[i].byte_en[3]) ram[index][(avl_vmon[i].address-ADDR_MAP_TAB_ADDR_BLOCK[index])/4][3]=avl_vmon[i].write_data[31:24];
      end
    end
  end
end
/********************************************************
监控读操作
********************************************************/
/*监视总线*/
always @(posedge clk or negedge rest) begin:block_1
  int i,index;
  read_cmd_t read_cmd;
  if(!rest) begin
    i=0;
    read_cmd_queue = {};
    for(i=0;i<MASTER_NUM;i++) begin
      value[i]=0;
    end
    read_data_valid=0;
  end
  else begin
    for(i=0;i<MASTER_NUM;i++) begin
      if(avl_vmon[i].read&&avl_vmon[i].request_ready) begin
        /*成功发出一条读指令,压入fifo*/
        index=addr_map(avl_vmon[i].address);
        read_cmd.addr   = avl_vmon[i].address;
        read_cmd.master = i;
        read_cmd.slave  = index;
        read_cmd_queue.push_front(read_cmd);
      end
      if(avl_vmon[i].read_data_valid&&avl_vmon[i].resp_ready) begin
        read_data_valid[i]=0;
      end
    end
    if((read_cmd_queue.size()>0)&&!read_data_valid[read_cmd_queue[0].master]) begin
    
      read_cmd=read_cmd_queue.pop_back();
      read_cmds[read_cmd.master]=read_cmd;
      read_data_valid[read_cmd.master]=1;
    end
  end
end
/*输出数据*/
always @(*) begin:block_2
  int i;
  if(!rest) begin
    for(i=0;i<MASTER_NUM;i++) begin
      value[i]=0;
    end
  end
  else begin
    for(i=0;i<MASTER_NUM;i++) begin
      value[i]=ram[read_cmds[i].slave][(read_cmds[i].addr-ADDR_MAP_TAB_ADDR_BLOCK[read_cmds[i].slave])/4];
    end
  end
end
/********************************************************
监控MASTER_NUM个主机接口一次发出了多少个命令
********************************************************/
always @(posedge clk) begin:block_3
  int i,count;
  count=0;
  for(i=0;i<MASTER_NUM;i++) begin
    if((avl_vmon[i].read||avl_vmon[i].write)&&avl_vmon[i].request_ready) begin
      count++;
    end
  end
  if(count>1) begin
    $error("More than one instruction is issued at a time");
    $stop();
  end
end

endmodule
