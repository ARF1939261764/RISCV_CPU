transcript on

vlib work

vlog -sv -work work +incdir+../../../rtl/core          {../../../rtl/core/core_type.sv  }
vlog -sv -work work +incdir+../../../rtl/bus           {../../../rtl/bus/avl_bus_type.sv}
vlog -sv -work work +incdir+../../../rtl/mux           {../../../rtl/mux/*.sv           }
vlog -sv -work work +incdir+../../../rtl/fifo          {../../../rtl/fifo/*.sv          }
vlog -sv -work work +incdir+../../../rtl/bus           {../../../rtl/bus/*.sv           }
vlog -sv -work work +incdir+../../../tb/core/02_core   {../../../tb/core/02_core/*.sv   }
vlog -sv -work work +incdir+../../../tb/common         {../../../tb/common/*.sv         }
vlog -sv -work work +incdir+../../../rtl/core          {../../../rtl/core/*.sv          }

vsim -t 1ps -L work -voptargs="+acc"  core_tb

add wave *
add wave -position end  sim:/core_tb/core_inst0/core_id_inst0/core_id_reg_file_inst0/regs

view structure
view signals

run -all

