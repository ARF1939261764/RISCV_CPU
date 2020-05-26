transcript on

vlib work

vlog -sv -work work +incdir+../../../rtl/core                     {../../../rtl/core/core_type.sv             }
vlog -sv -work work +incdir+../../../rtl/bus                      {../../../rtl/bus/avl_bus_type.sv           }
vlog -sv -work work +incdir+../../../tb/common                    {../../../tb/common/*.sv                    }
vlog -sv -work work +incdir+../../../tb/common                    {../../../tb/common/*.v                     }
vlog -sv -work work +incdir+../../../rtl/mux                      {../../../rtl/mux/*.sv                      }
vlog -sv -work work +incdir+../../../rtl/fifo                     {../../../rtl/fifo/*.sv                     }
vlog -sv -work work +incdir+../../../rtl/bus                      {../../../rtl/bus/*.sv                      }
vlog -sv -work work +incdir+../../../rtl/peripheral               {../../../rtl/peripheral/*.sv               }
vlog -sv -work work +incdir+../../../rtl/core                     {../../../rtl/core/*.sv                     }
vlog -sv -work work +incdir+../../../rtl/core_test/ram            {../../../rtl/core_test/ram/*.sv            }
vlog -sv -work work +incdir+../../../rtl/core_test/rom            {../../../rtl/core_test/rom/*.sv            }
#vlog -sv -work work +incdir+../../../rtl/core_test/pll            {../../../rtl/core_test/pll/*.sv           }
vlog -sv -work work +incdir+../../../rtl/core_test/ram            {../../../rtl/core_test/ram/*.v             }
vlog -sv -work work +incdir+../../../rtl/core_test/rom            {../../../rtl/core_test/rom/*.v             }
vlog -sv -work work +incdir+../../../rtl/core_test/pll            {../../../rtl/core_test/pll/*.v             }
vlog -sv -work work +incdir+../../../rtl/core_test                {../../../rtl/core_test/*.sv                }
vlog -sv -work work +incdir+../../../tb/core_test/01_core_test    {../../../tb/core_test/01_core_test/*.sv    }



vsim -t 100ps -L work -voptargs="+acc"  core_test_tb

add wave *

#log -r /*

view structure
view signals

run -all

