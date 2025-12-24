1. Multiple/conflicting drivers for `sram_ready`.
2. ~~Address bit slice is wrong.~~
3. ~~Read described as “async” but uses `@(posedge clk)`.~~
4. ~~Blocking assignments used in sequential logic; missing semicolons / syntax errors.~~
5. ~~Writes ignore `wstrb`.~~
6. ~~Read-during-write (write-through) behavior not handled.~~
7. Using `$readmemh` is simulation-only.
8. Prefer SystemVerilog `logic` / `always_ff` / `always_comb`.

### sram testbench
1. Memory initialization
2. Byte writes
3. Read-during-write
	1. Case A (same addr)
	2. Case B (different addr)

