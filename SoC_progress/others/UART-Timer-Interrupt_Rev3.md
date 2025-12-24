#### UART
- `baud ≈ clk_freq / (cfg_divider + 1)`
- "`uart_wrap` gives software two registers: a **divider** (at `addr==8`) that sets the baud clock, and a **data** register (at `addr==C`) you write to to transmit a byte or read from to receive a byte. The `simpleuart` module does the actual bit-level sending and sampling using those registers."
- "`cfg_divider` is the timing divider. The transmit and receive counters compare against it."
- Grug’s top-level explicitly says his UART is a “wrapper around the simpleuart from … picorv32.”
#### Timer
- there is a built in timer in the picoRV32 core 
- [picorv32/README.md at main · YosysHQ/picorv32](https://github.com/YosysHQ/picorv32/blob/main/README.md#timer)
- "PicoRV32’s timer is implemented _inline_ in the CPU file rather than as a separate peripheral module."
- The timer stops at zero and does not wrap/underflow.
- There is no automatic reload in this logic -it’s a one-shot countdown. If you want periodic interrupts you must either:
	- on IRQ handler, write `timer` again to reload, or
	- modify the core or SoC to attach a periodic external timer peripheral. (which is what grug huhler has done), or
	- modify the picorv32 core

```
1442:        if (ENABLE_IRQ && ENABLE_IRQ_TIMER && timer) begin
1443:            timer <= timer - 1;
1444:        end
.
.
.
1687:                    ENABLE_IRQ && ENABLE_IRQ_TIMER && instr_timer: begin
1688:                        latched_store <= 1;
1689:                        reg_out <= timer;
1690:                        `debug($display("LD_RS1: %2d 0x%08x", decoded_rs1, cpuregs_rs1);)
1691:                        timer <= cpuregs_rs1;
1692:                        dbg_rs1val <= cpuregs_rs1;
1693:                        dbg_rs1val_valid <= 1;
1694:                        cpu_state <= cpu_state_fetch;
1695:                    end
.
.
.
1915:        if (ENABLE_IRQ) begin
1916:            next_irq_pending = next_irq_pending | irq;
1917:            if(ENABLE_IRQ_TIMER && timer)
1918:                if (timer - 1 == 0)
1919:                    next_irq_pending[irq_timer] = 1;
1920:        end
```

#### interrupts
- [Tang Nano 9K Simple PicoRV32-based SoC on FPGA](https://www.youtube.com/watch?v=cq7ETOCPIBM)
- `ENABLE_IRQ_QREGS` enables non-standard registers (not native to rv32)
- there are a few other registers for interrupts (like `MASKED_IRQ`, `LATCHED_IRQ`, etc)
- basically picorv32 has some non standard instructions (not in the ISA of rv32) to work with interrupts (see the exact instructions and their details: [picorv32/README.md at main · YosysHQ/picorv32](https://github.com/YosysHQ/picorv32/blob/main/README.md#custom-instructions-for-irq-handling))
- picorv32's interrupt processing flow: ![[Pasted image 20251009210101.png]]
- there is some confusing/incorrect working in the documentation, refer to around 10:20 in the video
- grug huhler adds an additional library to his software side (the gcc compiler) that extends to his custom interrupt instructions

- PicoRV32 uses custom IRQ instructions instead of the full privileged interrupt mechanism so that it's compact for small SoCs
	- Toolchain/ABI assumptions: normal C code compiled with an ordinary toolchain won’t automatically include support for q-registers or `retirq`. Grug and the picoRV32 project provide assembler macros and samples so software can use them, but be careful if you try to compile arbitrary OS code or toolchain-generated ISR stubs.
    
	- If you expect standard RISC-V trap behaviour (M-mode / S-mode vectors, etc.), it won’t match -picoRV32’s approach is different by design.