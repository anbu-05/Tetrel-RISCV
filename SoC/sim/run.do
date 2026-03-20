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

add wave -divider "Clock and Reset"
add wave sim:/top_tb/clk
add wave sim:/top_tb/resetn

add wave -divider "AR channel"
add wave sim:/top_tb/dut/mem/ar_handshake/UPSD
add wave sim:/top_tb/dut/mem/ar_handshake/UPSV
add wave sim:/top_tb/dut/mem/ar_handshake/UPSR
add wave sim:/top_tb/dut/mem/ar_handshake/DNSD
add wave sim:/top_tb/dut/mem/ar_handshake/DNSV
add wave sim:/top_tb/dut/mem/ar_handshake/DNSR

add wave -divider "R channel"
add wave sim:/top_tb/dut/mem/r_handshake/UPSD
add wave sim:/top_tb/dut/mem/r_handshake/UPSV
add wave sim:/top_tb/dut/mem/r_handshake/UPSR
add wave sim:/top_tb/dut/mem/r_handshake/DNSD
add wave sim:/top_tb/dut/mem/r_handshake/DNSV
add wave sim:/top_tb/dut/mem/r_handshake/DNSR

add wave -divider "AW channel"
add wave sim:/top_tb/dut/mem/aw_handshake/UPSD
add wave sim:/top_tb/dut/mem/aw_handshake/UPSV
add wave sim:/top_tb/dut/mem/aw_handshake/UPSR
add wave sim:/top_tb/dut/mem/aw_handshake/DNSD
add wave sim:/top_tb/dut/mem/aw_handshake/DNSV
add wave sim:/top_tb/dut/mem/aw_handshake/DNSR

add wave -divider "W channel"
add wave sim:/top_tb/dut/mem/w_handshake/UPSD
add wave sim:/top_tb/dut/mem/w_handshake/UPSV
add wave sim:/top_tb/dut/mem/w_handshake/UPSR
add wave sim:/top_tb/dut/mem/w_handshake/DNSD
add wave sim:/top_tb/dut/mem/w_handshake/DNSV
add wave sim:/top_tb/dut/mem/w_handshake/DNSR

add wave -divider "mem insternals"

add wave -divider "B channel"
add wave sim:/top_tb/dut/mem/b_handshake/UPSD
add wave sim:/top_tb/dut/mem/b_handshake/UPSV
add wave sim:/top_tb/dut/mem/b_handshake/UPSR
add wave sim:/top_tb/dut/mem/b_handshake/DNSD
add wave sim:/top_tb/dut/mem/b_handshake/DNSV
add wave sim:/top_tb/dut/mem/b_handshake/DNSR

add wave -divider "mem internals"
add wave sim:/top_tb/dut/mem/write_ready
add wave sim:/top_tb/dut/mem/araddr_buffer
add wave sim:/top_tb/dut/mem/awaddr_buffer
add wave sim:/top_tb/dut/mem/wdata_buffer
add wave sim:/top_tb/dut/mem/wstrb_buffer
add wave sim:/top_tb/dut/mem_axi/wstrb

run 10ms