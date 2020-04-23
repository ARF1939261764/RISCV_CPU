`timescale 1ns/100ps
module bus_n2n_tb;

localparam  MASTER_NUM  = 8,
            SLAVE_NUM   = 16;

parameter int AVL_BUS_TEST_ADDR_MAP_TAB_FIELD_LEN[0:31]  = '{
              16,16,16,16,16,16,16,16,
              16,16,16,16,16,16,16,16,
              16,16,16,16,16,16,16,16,
              16,16,16,16,16,16,16,16
            };
parameter int AVL_BUS_TEST_ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{
              32'd00000000,32'd00010000,32'd00020000,32'd00030000,32'd00040000,32'd00050000,32'd00060000,32'd00070000,
              32'd00000000,32'd80000000,32'd80010000,32'd80020000,32'd80030000,32'd80040000,32'd80050000,32'd80060000,
              32'd00000000,32'd80000000,32'd80010000,32'd80020000,32'd80030000,32'd80040000,32'd80050000,32'd80060000,
              32'd00000000,32'd80000000,32'd80010000,32'd80020000,32'd80030000,32'd80040000,32'd80050000,32'd80060000
            };

i_avl_bus avl_master[MASTER_NUM-1:0]();
i_avl_bus avl_slave[SLAVE_NUM-1:0]();

logic       clk;
logic       rest;
logic[31:0] value[MASTER_NUM-1:0];

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
      .ADDR_MAP_TAB_FIELD_LEN (AVL_BUS_TEST_ADDR_MAP_TAB_FIELD_LEN ),
      .ADDR_MAP_TAB_ADDR_BLOCK(AVL_BUS_TEST_ADDR_MAP_TAB_ADDR_BLOCK)
    )
    avl_bus_master_sim_model_inst(
      .clk  (clk          ),
      .rest (rest         ),
      .value(value[i]     ),
      .avl_m(avl_master[i])
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
      .clk   (clk),
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
  .value        (value      )
);
/***总线控制器***/
avl_bus_n2n #(
  .MASTER_NUM                 (MASTER_NUM                           ),
  .SLAVE_NUM                  (SLAVE_NUM                            ),
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
