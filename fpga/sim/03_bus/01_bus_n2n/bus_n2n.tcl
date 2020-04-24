transcript on

vlib work

vlog -sv -work work +incdir+../../../rtl/bus           {../../../rtl/bus/avl_bus_type.sv  }
vlog -sv -work work +incdir+../../../tb/common         {../../../tb/common/*.sv           }
vlog -sv -work work +incdir+../../../rtl/define        {../../../rtl/define/*.sv          }
vlog -sv -work work +incdir+../../../rtl/mux           {../../../rtl/mux/*.sv             }
vlog -sv -work work +incdir+../../../rtl/fifo          {../../../rtl/fifo/*.sv            }
vlog -sv -work work +incdir+../../../rtl/bus           {../../../rtl/bus/*.sv             }
vlog -sv -work work +incdir+../../../tb/bus/01_bus_n2n {../../../tb/bus/01_bus_n2n/*.sv   }

vsim -t 1ps -L work -voptargs="+acc"  bus_n2n_tb

add wave *

add wave -position 2  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/sel

add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[0\]/read
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[0\]/write
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[0\]/resp_ready
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[0\]/request_ready

add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[1\]/read
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[1\]/write
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[1\]/resp_ready
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[1\]/request_ready

add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[2\]/read
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[2\]/write
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[2\]/resp_ready
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[2\]/request_ready

add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[3\]/read
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[3\]/write
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[3\]/resp_ready
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[3\]/request_ready

add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[4\]/read
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[4\]/write
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[4\]/resp_ready
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[4\]/request_ready

add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[5\]/read
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[5\]/write
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[5\]/resp_ready
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[5\]/request_ready

add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[6\]/read
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[6\]/write
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[6\]/resp_ready
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[6\]/request_ready

add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[7\]/read
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[7\]/write
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[7\]/resp_ready
add wave -position end  sim:/bus_n2n_tb/avl_bus_n2n_inst0/avl_bus_n21_inst0/avl_in\[7\]/request_ready

view structure
view signals

run -all

