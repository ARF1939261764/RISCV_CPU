`timescale 1ns/100ps
module bus_n2n_tb;
import avl_bus_type::*;
localparam  MASTER_NUM  = 8,
            SLAVE_NUM   = 16;

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
      .SLAVE_NUM              (SLAVE_NUM                           ),
      .MASTER_ID              (i                                   ),
      .ADDR_MAP_TAB_FIELD_LEN (AVL_BUS_TEST_ADDR_MAP_TAB_FIELD_LEN ),
      .ADDR_MAP_TAB_ADDR_BLOCK(AVL_BUS_TEST_ADDR_MAP_TAB_ADDR_BLOCK)
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
  .MASTER_NUM              (MASTER_NUM                          ),
  .SLAVE_NUM               (SLAVE_NUM                           ),
  .ADDR_MAP_TAB_FIELD_LEN  (AVL_BUS_TEST_ADDR_MAP_TAB_FIELD_LEN ),
  .ADDR_MAP_TAB_ADDR_BLOCK (AVL_BUS_TEST_ADDR_MAP_TAB_ADDR_BLOCK)
)
avl_bus_monitor_sim_model(
  .clk          (clk        ),
  .rest         (rest       ),
  .avl_mon      (avl_master ),
  .read_res     (read_res   )
);
/***总线控制器***/
avl_bus_n2n #(
  .MASTER_NUM                 (MASTER_NUM                           ),
  .SLAVE_NUM                  (SLAVE_NUM                            ),
  .ARB_METHOD                 (0                                    ),
  .BUS_N21_SEL_FIFO_DEPTH     (8                                    ),
  .BUS_N21_RES_DATA_FIFO_DEPTH(8                                    ),
  .BUS_12N_SEL_FIFO_DEPTH     (8                                    ),
  .ADDR_MAP_TAB_FIELD_LEN     (AVL_BUS_TEST_ADDR_MAP_TAB_FIELD_LEN  ),
  .ADDR_MAP_TAB_ADDR_BLOCK    (AVL_BUS_TEST_ADDR_MAP_TAB_ADDR_BLOCK )
)
avl_bus_n2n_inst0(
  .clk       (clk       ),
  .rest      (rest      ),
  .avl_master(avl_master),
  .avl_slave (avl_slave )
);

endmodule
