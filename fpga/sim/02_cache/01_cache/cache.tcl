transcript on

vlib work

vlog -sv -work work +incdir+../../../rtl/cache         {../../../rtl/cache/*.sv         }
vlog -sv -work work +incdir+../../../rtl/define        {../../../rtl/define/*.sv        }
vlog -sv -work work +incdir+../../../rtl/mux           {../../../rtl/mux/*.sv           }
vlog -sv -work work +incdir+../../../rtl/ram           {../../../rtl/ram/*.sv           }
vlog -sv -work work +incdir+../../../rtl/fifo          {../../../rtl/fifo/*.sv          }
vlog -sv -work work +incdir+../../../rtl/bus           {../../../rtl/bus/*.sv           }
vlog -sv -work work +incdir+../../../tb/common         {../../../tb/common/*.sv         }
vlog -sv -work work +incdir+../../../tb/cache/01_cache {../../../tb/cache/01_cache/*.sv }

vsim -t 1ps -L work -voptargs="+acc"  cache_tb

add wave *

view structure
view signals

run -all

