transcript on

vlib work
vlog -sv -work work +incdir+../../../../rtl/mux               {../../../../rtl/mux/*.sv             }
vlog -sv -work work +incdir+../../../../rtl/fifo              {../../../../rtl/fifo/*.sv            }
vlog -sv -work work +incdir+../../../../rtl/bus               {../../../../rtl/bus/*.sv             }
vlog -sv -work work +incdir+../../../../tb/core/01_core_if    {../../../../tb/core/01_core_if/*.sv  }
vlog -sv -work work +incdir+../../../../tb/common             {../../../../tb/common/*.sv           }
vlog -sv -work work +incdir+../../../../rtl/core              {../../../../rtl/core/*.sv            }

vsim -t 1ps -L work -voptargs="+acc"  core_if_tb

add wave *
view structure
view signals
run -all

