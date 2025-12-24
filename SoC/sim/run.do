# create & map work library
vlib work
vmap work work

# Compile design RTL (adjust path if needed)
# If you want compressed-isa defines like the Makefile, use +define+COMPRESSED_ISA
vlog ../rtl/picorv32.v
vlog ../rtl/simple_mem.sv
vlog ../rtl/simpleuart.v
vlog ../rtl/simpleuart_axi_adapter.sv
vlog ../rtl/top.sv
vlog ../rtl/axi_interf.sv
vlog ../rtl/axi_mux.sv

# Compile the tiny testbench (file in current dir)
vlog ../tb/top_tb.sv

# Launch simulation with accessibility for internal signals
vsim work.top_tb -voptargs="+acc"

# -------------------------------------------------------
# Clock + Reset
# -------------------------------------------------------
add wave -divider "Clock and Reset"
add wave sim:/top_tb/clk
add wave sim:/top_tb/resetn

# -------------------------------------------------------
# UART internal signals
# -------------------------------------------------------
add wave -divider "UART module signals"
add wave sim:/top_tb/dut/uart/ser_tx
add wave sim:/top_tb/dut/uart/ser_rx

add wave sim:/top_tb/dut/uart/reg_div_we
add wave sim:/top_tb/dut/uart/reg_div_di
add wave sim:/top_tb/dut/uart/reg_div_do

add wave sim:/top_tb/dut/uart/reg_dat_we
add wave sim:/top_tb/dut/uart/reg_dat_re
add wave sim:/top_tb/dut/uart/reg_dat_di
add wave sim:/top_tb/dut/uart/reg_dat_do
add wave sim:/top_tb/dut/uart/reg_dat_wait

# -------------------------------------------------------
# UART FSM signals (internal simpleuart_axi_adapter_mux)
# -------------------------------------------------------
add wave -divider "UART Read FSM"
add wave sim:/top_tb/dut/uart_adapter/read_fsm
add wave sim:/top_tb/dut/uart_adapter/mem_read_addr_buffer
add wave sim:/top_tb/dut/uart_adapter/mem_read_buffer
add wave sim:/top_tb/dut/uart_adapter/read_word_index

add wave -divider "UART Write FSM"
add wave sim:/top_tb/dut/uart_adapter/write_fsm
add wave sim:/top_tb/dut/uart_adapter/write_word_index
add wave sim:/top_tb/dut/uart_adapter/mem_write_addr_buffer
add wave sim:/top_tb/dut/uart_adapter/debug

# -------------------------------------------------------
# AXI Routing Through MUX (optional)
# -------------------------------------------------------

add wave -divider "AXI Mux Output → Slave1 (uart_axi)"
add wave sim:/top_tb/dut/uart_axi/*

add wave -divider "AXI Mux Output → Slave0 (mem_axi)"
add wave sim:/top_tb/dut/mem_axi/*

# -------------------------------------------------------
# AXI Interface Observability
# -------------------------------------------------------

add wave -divider "AXI - PICORV32 Master"
add wave sim:/top_tb/dut/picorv32_axi/*

add wave -divider "AXI - MEM Slave"
add wave sim:/top_tb/dut/mem_axi/*

add wave -divider "AXI - UART Slave"
add wave sim:/top_tb/dut/uart_axi/*


run 3us
