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

view structure
view signals

run -all

