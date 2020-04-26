`timescale 1ns/100ps
`include "../../rtl/bus/avl_bus_define.sv"
import avl_bus_type::*;

/*这里定义一个全局变量,用来记录所有该module实例成功读出数据的总次数*/
logic[31:0] read_success_count=0;

module avl_bus_master_sim_model #(
  parameter     SLAVE_NUM                     = 16,
                MASTER_ID                     = 0,
            int ADDR_MAP_TAB_FIELD_LEN[31:0]  = '{32{32'd22}},
            int ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{32{1'd0}}
)(
  input logic          clk,
  input logic          rest,
  input read_cmd_res_t read_res,
  i_avl_bus.master     avl_m
);
logic cmd_valid;
/***清除命令***********************/
function void clear_cmd();
  avl_m.address=0;
  avl_m.byte_en=0;
  avl_m.read=0;
  avl_m.write=0;
  avl_m.write_data=0;
  avl_m.begin_burst_transfer=0;
  avl_m.burst_count=0;
endfunction

/***发送命令***********************/
/*常规*/
function void send_cmd();
  logic[31:0] temp,offset,index;
  temp=$random();
  if(SLAVE_NUM==1) begin
    index=0;  
  end
  else begin
    index=temp[($clog2(SLAVE_NUM)?$clog2(SLAVE_NUM):1)-1:0];/*随机选择一个从机*/
  end
  offset={$random()}%(2**(32-ADDR_MAP_TAB_FIELD_LEN[index]));         /*计算从机内地址偏移*/
  avl_m.address=ADDR_MAP_TAB_ADDR_BLOCK[index]+{offset[31:2],2'd0}; /*基址+offset*/
  temp=$random();
  avl_m.byte_en=(temp[1:0]==2'd0)?4'b0001:
                (temp[1:0]==2'd1)?4'b0011:
                (temp[1:0]==2'd2)?4'b1111:
                4'b1111;
  temp=$random();
  avl_m.read=temp[0]&&temp[1];
  avl_m.write=!avl_m.read&&temp[1];
  avl_m.write_data=$random();
  avl_m.begin_burst_transfer=(temp[6:2]==0)&&temp[1];
  avl_m.burst_count=avl_m.begin_burst_transfer?$random()%`ALV_BURST_MAX_COUNT:1'd0;
  if( avl_m.begin_burst_transfer&&
      ((avl_m.burst_count*4+offset)>(2**(32-ADDR_MAP_TAB_FIELD_LEN[index])))) begin
    /*如果突发访问越界,则需要修改地址*/
    avl_m.address=ADDR_MAP_TAB_ADDR_BLOCK[index]+(2**(32-ADDR_MAP_TAB_FIELD_LEN[index]))-(avl_m.burst_count+1)*4;
  end
endfunction
/*突发*/
function void send_burst_cmd();
  logic[31:0] temp;                              /*随机选择一个从机*/
  avl_m.address+=4;
  temp=$random();
  avl_m.byte_en=(temp[1:0]==2'd0)?4'b0001:
                (temp[1:0]==2'd1)?4'b0011:
                (temp[1:0]==2'd2)?4'b1111:
                4'b1111;
  avl_m.write_data=$random();
  avl_m.begin_burst_transfer=0;
  avl_m.burst_count--;
endfunction
/***接收并验证数据是否正确***********/
logic stop;
function void receive_cmd();
  if(avl_m.resp_ready&&avl_m.read_data_valid) begin
    if((avl_m.read_data==read_res.value)&&(read_res.master==MASTER_ID)) begin
      read_success_count++;
      $display("read data success:master=%2d,slave=%2d,addr=%h,data=%h,value=%h,count=%d,fifo_size=%2d",MASTER_ID,read_res.slave,read_res.addr,avl_m.read_data,read_res.value,read_success_count,read_res.fifo_size);
    end
    else begin
      $error("read data fail,master=%2d,slave=%2d,addr=%h,read_data=%h,read_res.value=%h,addr=%h,fifo_size=%2d",MASTER_ID,read_res.slave,read_res.addr,avl_m.read_data,read_res.value,read_res.addr,read_res.fifo_size);
      stop=1;
    end
  end
endfunction
/***stop************************/
always @(posedge clk) begin
  /*延迟一个时钟周期再停止,以观察发生错误时的状况*/
  if(stop) begin
    $stop();
  end
end
/***初始化************************/
initial begin
  logic[31:0] temp;
  stop=0;
  send_cmd();
  temp=$random();
  avl_m.resp_ready=temp[0];
end
/***发送命令***********************/
localparam  send_cmd_state_normal=1'd0,
            send_cmd_state_burst =1'd1;
logic send_cmd_state;
always @(posedge clk or negedge rest) begin:block_01
  if(!rest) begin
    clear_cmd();
    cmd_valid=0;
    send_cmd_state=send_cmd_state_normal;
  end
  else begin
    case(send_cmd_state)
      send_cmd_state_normal:begin
          if(avl_m.request_ready||!cmd_valid||!(avl_m.read||avl_m.write)) begin
            cmd_valid=1;
            send_cmd();
            if(avl_m.begin_burst_transfer&&(avl_m.burst_count!=0)) begin
              send_cmd_state=send_cmd_state_burst;
            end
          end
        end
      send_cmd_state_burst:begin
          if(avl_m.request_ready||!cmd_valid||!(avl_m.read||avl_m.write)) begin
            cmd_valid=1;
            send_burst_cmd();
          end
          if(avl_m.burst_count==0) begin
            send_cmd_state=send_cmd_state_normal;
          end
        end
      default:begin
        end
    endcase
  end
end
/***接收并验证数据是否正确***********/
always @(posedge clk or negedge rest) begin:block_02
  logic[31:0] temp;
  if(!rest) begin
  end
  else begin
    receive_cmd();
    temp=$random();
    avl_m.resp_ready=temp[0];
  end
end

endmodule