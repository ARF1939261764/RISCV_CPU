`timescale 1ns/100ps
import avl_bus_type::*;
module cache_tb;

/**********************************************************
config
**********************************************************/
localparam TEST_CONFIG_MEM_SIZE																=	32*1024*1024;
localparam TEST_CONFIG_CACHE_SIZE															=	8*1024;
localparam TEST_CONFIG_CACHE_BLOCK_SIZE												=	64;
localparam TEST_CONFIG_MASTER_SIM_MODEL_RECORD_SEND_CMD_EN    = 0;  /*记录主机发送的所用命令 0:失能 1:使能*/
localparam TEST_CONFIG_MONITOR_SIM_MODEL_RECORD_SEND_CMD_EN   = 0;  /*记录监视器监视到的所有命令 0:失能 1:使能*/
localparam TEST_CONFIG_SDRAM_SIM_MODEL_RECORD_SEND_CMD_EN     = 0;

/**********************************************************
总线地址映射表
**********************************************************/
parameter int AVL_BUS_CACHE_ADDR_MAP_TAB_FIELD_LEN[0:31]  = '{
              7,16,16,16,16,16,16,16,
              0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0
            };
parameter int AVL_BUS_CACHE_ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000
            };
/**********************************************************
其它
**********************************************************/
logic clk,rest;
i_avl_bus alv_bus_cpu[0:0]();
i_avl_bus alv_bus_mem[0:0]();
i_avl_bus avl_bus_default[1:0]();

read_cmd_res_t read_cmd_res[0:0];
/**********************************************************
时钟、复位、初始化
**********************************************************/
initial begin
	clk=0;
	rest=0;
	#100;
	rest=1;
end

always #10 clk=~clk;

/**********************************************************
主机
**********************************************************/
avl_bus_master_sim_model #(
  .SLAVE_NUM              (1),
  .MASTER_ID              (0),
  .RECORD_SEND_CMD_EN     (TEST_CONFIG_MASTER_SIM_MODEL_RECORD_SEND_CMD_EN),
	.ALWAYS_RECEIVE_DATA		(1),
  .ADDR_MAP_TAB_FIELD_LEN (AVL_BUS_CACHE_ADDR_MAP_TAB_FIELD_LEN),
  .ADDR_MAP_TAB_ADDR_BLOCK(AVL_BUS_CACHE_ADDR_MAP_TAB_ADDR_BLOCK)
)
avl_bus_master_sim_model_inst0(
  .clk		 (clk 					 ),
  .rest		 (rest 					 ),
  .read_res(read_cmd_res[0]),
  .avl_m	 (alv_bus_cpu[0] )
);
/**********************************************************
监视器
**********************************************************/
avl_bus_monitor_sim_model #(
  .MASTER_NUM             (1),
  .SLAVE_NUM              (1),
  .RECORD_SEND_CMD_EN     (TEST_CONFIG_MONITOR_SIM_MODEL_RECORD_SEND_CMD_EN),
  .ADDR_MAP_TAB_FIELD_LEN (AVL_BUS_CACHE_ADDR_MAP_TAB_FIELD_LEN),
  .ADDR_MAP_TAB_ADDR_BLOCK(AVL_BUS_CACHE_ADDR_MAP_TAB_ADDR_BLOCK)
)
avl_bus_monitor_sim_model_inst0(
  .clk		 (clk   			),
  .rest		 (rest 				),
  .avl_mon (alv_bus_cpu	),
  .read_res(read_cmd_res)
);
/**********************************************************
cache
**********************************************************/
cache #(
	.SIZE			 (TEST_CONFIG_CACHE_SIZE 			),
  .BLOCK_SIZE(TEST_CONFIG_CACHE_BLOCK_SIZE)
)
cache_inst0(
  .clk 	 (clk 							),
  .rest	 (rest 							),
  .avl_s0(alv_bus_cpu[0]	  ),
  .avl_s1(avl_bus_default[1]),
  .avl_m0(alv_bus_mem[0]		)
);
/**********************************************************
默认主机
**********************************************************/
avl_bus_default_master avl_bus_default_master_inst0(
  .avl_m(avl_bus_default[0])
);

/**********************************************************
sdram sim model
**********************************************************/
sdram_sim_model #(
  .SIZE(TEST_CONFIG_MEM_SIZE/1024),
  .RECORD_SEND_CMD_EN(TEST_CONFIG_SDRAM_SIM_MODEL_RECORD_SEND_CMD_EN)
)
sdram_sim_model_inst0(
  .clk 	 (clk 				  ),
  .rest  (rest 					),
  .avl_m0(alv_bus_mem[0])
);

/**********************************************************
cache与sdram一致性检测
**********************************************************/
/*
localparam DATA_RAM_ADDR_WIDTH=$clog2(TEST_CONFIG_CACHE_SIZE/4/4);

`define sdram_ram sdram_sim_model_inst0.ram
`define cache_ram cache_inst0.cache_rw_inst0.cache_rw_data_inst0.cache_rw_data_ram_inst0.dualPortRam_inst0_dataRam.ram
`define cache_dre cache_inst0.cache_rw_inst0.cache_rw_dre_inst0.cache_rw_dre_ram_inst0.dualPortRam_inst0_dreRam.ram
`define cache_tag cache_inst0.cache_rw_inst0.cache_rw_tag_inst0.cache_rw_tag_ram_inst0.dualPortRam_inst0_tagRam.ram

logic read_in_done;
logic write_back_done;
logic[31:0] sdram_base_addr;
logic[31:0] cache_base_addr;
logic[1:0]  cache_way;
logic[3:0]  cache_ri_state;

assign read_in_done=cache_inst0.cache_ri_inst0.end_state_readIn&&(cache_ri_state==cache_inst0.cache_ri_inst0.state_readIn);
assign write_back_done=cache_inst0.cache_ri_inst0.end_state_writeBack&&(cache_ri_state==cache_inst0.cache_ri_inst0.state_writeBack);
assign cache_ri_state=cache_inst0.cache_ri_inst0.state;

always @(posedge clk or negedge rest) begin:block1
  if(!rest) begin
    sdram_base_addr=0;
    cache_base_addr=0;
  end
  else begin
    int i;
    logic[3:0][7:0] cache_data,sdram_data;
    logic[3:0] cache_dre_info;
    if(write_back_done) begin
      sdram_base_addr=cache_inst0.cache_ri_inst0.address_a/4;
      cache_base_addr=(sdram_base_addr*4%2048)/4;
    end
    if(write_back_done) begin
      cache_way=cache_inst0.cache_ri_inst0.rwChannel;
      for(i=0;i<TEST_CONFIG_CACHE_BLOCK_SIZE/4;i++) begin
        cache_data= (`cache_ram[cache_base_addr+i][cache_way*4+3]<<24)|
                    (`cache_ram[cache_base_addr+i][cache_way*4+2]<<16)|
                    (`cache_ram[cache_base_addr+i][cache_way*4+1]<< 8)|
                    (`cache_ram[cache_base_addr+i][cache_way*4+0]<< 0);
        sdram_data= `sdram_ram[sdram_base_addr+i];
        cache_dre_info=i[0]?`cache_dre[(cache_base_addr+i)/2][cache_way][7:4]:`cache_dre[(cache_base_addr+i)/2][cache_way][3:0];
        assert(
          (!cache_dre_info[3]||(cache_data[3]==sdram_data[3]))&&
          (!cache_dre_info[2]||(cache_data[2]==sdram_data[2]))&&
          (!cache_dre_info[1]||(cache_data[1]==sdram_data[1]))&&
          (!cache_dre_info[0]||(cache_data[0]==sdram_data[0]))
        ) else begin
          $display("Error:Data Inconsistency,cache_addr=%x,cache_way=%01x,cache=%x,sdram_addr=%x,sdram=%x,cache=%x,dre=%1x",cache_base_addr+i,cache_way,cache_data,sdram_base_addr+i,sdram_data,`cache_ram[cache_base_addr+i],cache_dre_info);
          $stop();
        end
      end
    end
  end
end
*/

endmodule