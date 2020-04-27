`timescale 1ns/100ps
import avl_bus_type::*;
module bus_n2n_tb;
/*****************************************************************************
测试配置
*****************************************************************************/
localparam TEST_CONFIG_MASTER_NUM                             =16;  /*主机数量(1,2,4,8,16)*/
localparam TEST_CONFIG_SLAVE_NUM                              = 1;  /*从机数量(1,2,4,8,16)*/
localparam TEST_CONFIG_ARB_METHOD                             = 0;  /*仲裁方法: 0:轮询仲裁,1:固定优先级仲裁*/
localparam TEST_CONFIG_BUS_N21_SEL_FIFO_DEPTH                 = 8;  /*n21模块内部sel信号fifo深度(>2)*/
localparam TEST_CONFIG_BUS_12N_SEL_FIFO_DEPTH                 = 8;  /*12n模块内部sel信号fifo深度(>2)*/
localparam TEST_CONFIG_BUS_N21_RES_DATA_FIFO_DEPTH            = 0;  /*n21模块内部反馈数据fifo深度(≥0)*/
localparam TEST_CONFIG_MASTER_SIM_MODEL_RECORD_SEND_CMD_EN    = 0;  /*记录主机发送的所用命令 0:失能 1:使能*/
localparam TEST_CONFIG_MONITOR_SIM_MODEL_RECORD_SEND_CMD_EN   = 0;  /*记录监视器监视到的所有命令 0:失能 1:使能*/
/*****************************************************************************
测试正文
*****************************************************************************/
localparam  MASTER_NUM  = TEST_CONFIG_MASTER_NUM,
            SLAVE_NUM   = TEST_CONFIG_SLAVE_NUM;

parameter int AVL_BUS_TEST_ADDR_MAP_TAB_FIELD_LEN[0:31]  = '{
              16,16,16,16,16,16,16,16,
              16,16,16,16,16,16,16,16,
              16,16,16,16,16,16,16,16,
              16,16,16,16,16,16,16,16
            };
parameter int AVL_BUS_TEST_ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{
              32'h00000000,32'h00010000,32'h00020000,32'h00030000,32'h00040000,32'h00050000,32'h00060000,32'h00070000,
              32'h00080000,32'h00090000,32'h000a0000,32'h000b0000,32'h000c0000,32'h000d0000,32'h000e0000,32'h000f0000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000
            };

i_avl_bus avl_master[MASTER_NUM-1:0]();
i_avl_bus avl_slave[SLAVE_NUM-1:0]();

logic          clk;
logic          rest;
read_cmd_res_t read_res[MASTER_NUM-1:0];

initial begin
  clk=0;
  rest=0;
  #100 rest=1;
end

always #10 clk=~clk;

/***********************************************************************************
模块实例化
***********************************************************************************/
genvar i;
/***模拟主机***/
generate
  for(i=0;i<MASTER_NUM;i++) begin:block_0
    avl_bus_master_sim_model #(
      .SLAVE_NUM              (SLAVE_NUM                                      ),
      .MASTER_ID              (i                                              ),
      .RECORD_SEND_CMD_EN     (TEST_CONFIG_MASTER_SIM_MODEL_RECORD_SEND_CMD_EN),
      .ADDR_MAP_TAB_FIELD_LEN (AVL_BUS_TEST_ADDR_MAP_TAB_FIELD_LEN            ),
      .ADDR_MAP_TAB_ADDR_BLOCK(AVL_BUS_TEST_ADDR_MAP_TAB_ADDR_BLOCK           )
    )
    avl_bus_master_sim_model_inst(
      .clk     (clk          ),
      .rest    (rest         ),
      .read_res(read_res[i]  ),
      .avl_m   (avl_master[i])
    );
  end
endgenerate
/***模拟从机***/
generate
  for(i=0;i<SLAVE_NUM;i++) begin:block_1
    sdram_sim_model #(
      .SIZE(2**(32-AVL_BUS_TEST_ADDR_MAP_TAB_FIELD_LEN[i])/1024)
    )
    sdram_sim_model_inst(
      .clk   (clk         ),
      .rest  (rest        ),
      .avl_m0(avl_slave[i])
    );
  end
endgenerate
/***总线监视器***/
avl_bus_monitor_sim_model #(
  .MASTER_NUM              (MASTER_NUM                                      ),
  .SLAVE_NUM               (SLAVE_NUM                                       ),
  .RECORD_SEND_CMD         (TEST_CONFIG_MONITOR_SIM_MODEL_RECORD_SEND_CMD_EN),
  .ADDR_MAP_TAB_FIELD_LEN  (AVL_BUS_TEST_ADDR_MAP_TAB_FIELD_LEN             ),
  .ADDR_MAP_TAB_ADDR_BLOCK (AVL_BUS_TEST_ADDR_MAP_TAB_ADDR_BLOCK            )
)
avl_bus_monitor_sim_model(
  .clk          (clk        ),
  .rest         (rest       ),
  .avl_mon      (avl_master ),
  .read_res     (read_res   )
);
/***总线控制器***/
avl_bus_n2n #(
  .MASTER_NUM                 (MASTER_NUM                              ),
  .SLAVE_NUM                  (SLAVE_NUM                               ),
  .ARB_METHOD                 (TEST_CONFIG_ARB_METHOD                  ),
  .BUS_N21_SEL_FIFO_DEPTH     (TEST_CONFIG_BUS_N21_SEL_FIFO_DEPTH      ),
  .BUS_N21_RES_DATA_FIFO_DEPTH(TEST_CONFIG_BUS_N21_RES_DATA_FIFO_DEPTH ),
  .BUS_12N_SEL_FIFO_DEPTH     (TEST_CONFIG_BUS_12N_SEL_FIFO_DEPTH      ),
  .ADDR_MAP_TAB_FIELD_LEN     (AVL_BUS_TEST_ADDR_MAP_TAB_FIELD_LEN     ),
  .ADDR_MAP_TAB_ADDR_BLOCK    (AVL_BUS_TEST_ADDR_MAP_TAB_ADDR_BLOCK    )
)
avl_bus_n2n_inst0(
  .clk       (clk       ),
  .rest      (rest      ),
  .avl_in    (avl_master),
  .avl_out   (avl_slave )
);

endmodule
