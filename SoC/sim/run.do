# create & map work library
vlib work
vmap work work

# Compile design RTL (adjust path if needed)
# If you want compressed-isa defines like the Makefile, use +define+COMPRESSED_ISA
vlog ../sourcecode/rtl/*.v
vlog ../sourcecode/rtl/*.sv
vlog ../sourcecode/tb/*.sv

# Launch simulation with accessibility for internal signals
vsim -voptargs="+acc" work.top_tb 

# -------------------------------------------------------
# Clock + Reset
# -------------------------------------------------------
add wave -divider "Clock and Reset"
add wave sim:/top_tb/clk
add wave sim:/top_tb/resetn

# -------------------------------------------------------
# AXI Interface Observability
# -------------------------------------------------------

add wave -divider "uart outputs"
add wave sim:/top_tb/dut/uart/ser_tx
add wave sim:/top_tb/dut/uart/ser_rx

add wave -divider "PicoRV32"
add wave sim:/top_tb/dut/core/mem_valid
add wave sim:/top_tb/dut/core/mem_ready
add wave sim:/top_tb/dut/core/mem_addr
add wave sim:/top_tb/dut/core/mem_wdata
add wave sim:/top_tb/dut/core/mem_wstrb
add wave sim:/top_tb/dut/core/mem_rdata

add wave -divider "AXI - core master"
add wave sim:/top_tb/dut/picorv32_axi/*

add wave -divider "AXI - mem slave"
add wave sim:/top_tb/dut/mem_axi/*

add wave -divider "simple_mem"
add wave sim:/top_tb/dut/mem/*

add wave -divider "AXI - uart slave"
add wave sim:/top_tb/dut/uart_axi/*

add wave -divider "simpleuart"
add wave sim:/top_tb/dut/uart/*

add wave -divider "AXI - gpio slave"
add wave sim:/top_tb/dut/gpio_axi/*

add wave -divider "simplegpio"
add wave sim:/top_tb/dut/gpio/*


run 10ms
