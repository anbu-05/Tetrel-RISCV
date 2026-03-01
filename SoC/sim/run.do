# create & map work library
vlib work
vmap work work

# Compile design RTL (adjust path if needed)
# If you want compressed-isa defines like the Makefile, use +define+COMPRESSED_ISA
vlog ../rtl/*.v
vlog ../rtl/*.sv

# Launch simulation with accessibility for internal signals
vsim -voptargs="+acc" work.top_tb 

# -------------------------------------------------------
# Clock + Reset
# -------------------------------------------------------
add wave -divider "Clock and Reset"
add wave sim:/top_tb/clk
add wave sim:/top_tb/resetn

# -------------------------------------------------------
# AXI Routing Through MUX (optional)
# -------------------------------------------------------

#add wave -divider "AXI Mux Output → Slave1 (uart_axi)"
#add wave sim:/top_tb/dut/uart_axi/*

#add wave -divider "AXI Mux Output → Slave0 (mem_axi)"
#add wave sim:/top_tb/dut/mem_axi/*

# -------------------------------------------------------
# AXI Interface Observability
# -------------------------------------------------------

add wave -divider "AXI - MEM Slave"
add wave sim:/top_tb/dut/mem_axi/*
add wave sim:/top_tb/dut/mem_adapter/read_pending

add wave -divider "simple_mem"
add wave sim:/top_tb/dut/mem/*

add wave -divider "AXI - PICORV32 Master"
add wave sim:/top_tb/dut/picorv32_axi/*

add wave -divider "AXI - UART Slave"
add wave sim:/top_tb/dut/uart_axi/*


run 500ns
