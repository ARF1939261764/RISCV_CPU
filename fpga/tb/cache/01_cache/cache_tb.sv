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
  .SIZE(TEST_CONFIG_MEM_SIZE/1024)
)
sdram_sim_model_inst0(
  .clk 	 (clk 				  ),
  .rest  (rest 					),
  .avl_m0(alv_bus_mem[0])
);

endmodule