module alv_bus_master_sim_model #(
  parameter     SLAVE_NUM                     = 8,
            int ADDR_MAP_TAB_FIELD_LEN[31:0]  = '{32{32'd22}},
            int ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{32{1'd0}}
)(
  input logic       clk,
  input logic       rest,
  input logic[31:0] value,
  i_avl_bus.master  avl_m
);
/***发送命令***********************/
function void send_cmd();
  logic[31:0] temp,offset,index;
  temp=$random();
  index=temp[$clog2(SLAVE_NUM)-1:0];                                /*随机选择一个从机*/
  offset=$random()%(2**(32-ADDR_MAP_TAB_FIELD_LEN[index]));         /*计算从机内地址偏移*/
  avl_m.address=ADDR_MAP_TAB_ADDR_BLOCK[index]+{offset[31:2],2'd0}; /*基址+offset*/
  temp=$random();
  avl_m.byte_en=(temp[1:0]==2'd0)?4'b0001:
                (temp[1:0]==2'd1)?4'b0011:
                (temp[1:0]==2'd2)?4'b1111:
                4'b1111;
  avl_m.read=temp[2];
  avl_m.write=!avl_m.read;
  avl_m.write_data=$random();
  avl_m.begin_burst_transfer=0;
  avl_m.burst_count=0;
endfunction
/***接收并验证数据是否正确***********/
function void receive_cmd();
  logic[31:0] temp;
  if(avl_m.resp_ready) begin
    if(avl_m.read_data!=value) begin
      $error("read data fail,read_data=%d,value=%d",read_data,value);
    end
  end
  temp=$random();
  avl_m.resp_ready=temp[0];
endfunction
/***初始化************************/
initial begin
  logic[31:0] temp;
  send_cmd();
  temp=$random();
  avl_m.resp_ready=temp[0];
end
/***发送命令***********************/
always @(posedge clk) begin:block_01
  if(avl_m.request_ready) begin
    send_cmd();
  end
end
/***接收并验证数据是否正确***********/
always @(posedge clk) begin
  if(avl_m.resp_ready) begin
    receive_cmd();
  end
end

endmodule