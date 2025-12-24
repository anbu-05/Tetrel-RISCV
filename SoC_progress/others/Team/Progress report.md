# custom RISCV32 Core
all the progress for the custom RISCV32 CPU can be found here:
[anbu-05/RISCV-SoC at module/RISCV_core](https://github.com/anbu-05/RISCV-SoC/tree/module/RISCV_core)

21 instructions were implemented and tested

but then i realised that if we're going to manufacture, there's no way we could build a core as good as picorv32

and as complete amateurs, instead of focusing on making the core, we should focus on one level higher, making the CPU/SoC

we have to worry about making an APB bus, a UART controller, a GPIO controller, and connecting everything together with the core first

we'll use and modify the core as we go, but we clearly dont have the expertise yet to make a good enough core.

we can, and there have been single cycle implementations of the picorv32

# Modified picorv32
so i went back to the picorv32 github page. copy pasted picorv32.v and started off with testbench_ez.

i understood the basic memory interface of the picorv32, and it works very similar to the custom core that i made

here's the result of a basic assembly program:

```
        memory[0] = 32'h 3fc00093; //       li      x1,1020
        memory[1] = 32'h 0000a023; //       sw      x0,0(x1)
        memory[2] = 32'h 0000a103; // loop: lw      x2,0(x1)
        memory[3] = 32'h 00110113; //       addi    x2,x2,1
        memory[4] = 32'h 0020a023; //       sw      x2,0(x1)
        memory[5] = 32'h ff5ff06f; //       j       <loop>
```

![[Pasted image 20251026034159.png]]

but it can do a lot more a lot perfectly. in the picorv32 they write C code for a benchmark called the dhrystone benchmark

dhrystone is a very popular microcontroller benchmark tool.


> - You **write a program** (C or assembly), compile it into a `.hex` (the Makefile does that) and the testbench **loads that hex into simulated memory** (`$readmemh` into `mem.memory`).
> 
> - The testbench runs the core on that memory image.
> 
> - The program can print characters by writing to `0x10000000` (the bench prints them to STDOUT), and can signal success by writing `123456789` to `0x20000000`.
> 
> - The testbench does **not** automatically dump the whole simulated memory to disk by default -but you can add a line to do that (I'll show how).