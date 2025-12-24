### 13 may
- finally got simulation working on quartus prime after a lot of work
- [can you make an easy-to-follow tutorial to get the simulation up and running?...](https://www.perplexity.ai/search/can-you-make-an-easy-to-follow-3E0_5UZYRbGqW0mCqE26Vw) -this convo's last prompt has everything you need to get everything up and running
- need to go through the previous files that ive worked on. study everything, and remake this cpu core from scratch. need to make it in a much cleaner way this time, since ive gotten used to the workflow.

### 14 may
- copied everything to a new project, set up the workspace
---
- made a list of all the instructions, with if theyre implemented or not, and if they need testing or not
- noted down the progress before the hiatus from notebook

### 20 may
- fixed the compiler to not add 0x infront of each line
- changed IMem file such that it can be simulated on questa and synthesized 
- tried example_program_3 -the program works fine but there are some problems with my implementation of branch and jump instructions compared to the RISCV32I ISA. i need to check, and make notes, and redo all the branch and jump instructions

----
### 30 Aug
- there's been a second hiatus. great
- met with professor. now there's some direction to this project
- started restructuring the entire project. since i learnt about testbench automation/testcases/running scripts, CLI simulation and stuff, i am gonna follow that

- created a new RISCV_core project on quartus.
- remade the program counter -and made it a bit simpler.
- found out the required testcases for testing a program counter and made a testbench that saves the testcases' result in a log file: [Program counter testbench](https://chatgpt.com/c/68b3447f-b1a4-8330-b84a-c14acbbfe17e)
- trying to make the new restructure be both simulation and synthesis friendly.

- i am using vscode for running the commands. need to dualboot linux asap to move to that
- trying to simulate the testbench: [questa testbench simulation](https://chatgpt.com/c/68b350fe-cd4c-832f-a9e0-d57896a86450)

- need to fix README.md

### 31 Aug
- setting up simulation environment: https://chatgpt.com/s/t_68b3e52e1d888191bf106327f6f85d1a, https://chatgpt.com/s/t_68b3ee2b9c18819189ade1abd3c0ceaf
- `vsim` to run modelsim/questa (`vsim -c` doesnt work for the next command for some reason)
- `do sim/run.do` to run simulation
- finally got a .do file working to initiate modelsim for simulation

(need to include a way to program the IMem when making it)


### 1 Sep
- added more testcases to ProgramCounter module

### 2 Sep
- finished the first fully functional testbench with logging
- [Fixing testbench errors](https://chatgpt.com/c/68b6e851-c094-8325-b1d8-841f7c2958e3)
- need to discuss the core specs with saravana

---
### 12 Sep
- restructured RISCV_core based on a structure taught in SLV class
- going through grug huhler's picoRV32. his goals are very aligned to ours
- read the [[notes]]
- need to look into adding a submodule
```
hint: You've added another git repository inside your current repository.
hint: Clones of the outer repository will not contain the contents of
hint: the embedded repository and will not know how to obtain it.
hint: If you meant to add a submodule, use:
hint:
hint:   git submodule add <url> pico/picorv32
hint:
hint: If you added this path by mistake, you can remove it from the
hint: index with:
hint:
hint:   git rm --cached pico/picorv32
hint:
hint: See "git help submodule" for more information.
hint: Disable this message with "git config set advice.addEmbeddedRepo false"
```

---
- trying to modify grug huhler's picorv32 to get it working on a DE2-115
- everything else is fine, only top.v, sram.v, and gowin_sp.v are creating problems
- when compiling in quartus, Quartus expects a different name for the top level entitiy: fix for that:
## ✅ Fix
You need to **tell Quartus the correct top-level entity**:
1. Open your `.qsf` (project settings file) in a text editor or Quartus GUI.
2. Find the line:
    `set_global_assignment -name TOP_LEVEL_ENTITY picorv32-DE2115`
3. Change it to:
    `set_global_assignment -name TOP_LEVEL_ENTITY top`
(or whichever module you want as the FPGA top — probably `top` in `top.v`).

- sram.v and gowin_sp.v are causing problems because they are files designed for the tang nano 9k FPGA. read about it [RISCV_core - Compare RISCV cores (last prompt)](https://chatgpt.com/g/g-p-68c2b3f837f88191bf603055f1e243ba/c/68c2b6be-b6d4-832e-8d5e-baee84fe72a3)
- since quartus prefers inferred ram, i will be changing gowin_sp to inferred ram. quartus will automatically map this to it's M9K memory
- i will need to change mem_init.sv to mem_init.hex as well

- made the changes. now the sram problem is probably fixed and everything compiles.

tomorrow:
- need to figure out what this program that ive loaded in mem_init.hex actually does + need to change the LED init file as that also changes for DE2-115
- need to go through sram_infer

### 13 Sep

- meeting [[MoM 13 Sep]]:
	- looked into picorv32 implementation by grug huhler (https://github.com/grughuhler/picorv32/tree/main)
	- we need to split into two teams
		- implement this on different synthesis tool like cadence/synopsis
		- make a block diagram -refer to ravensoc and based on grug huhler's picorv32
	
	- there are other teams working on SoCs -we have competition, and we need to make the best core to get budget for tapeout.
	- try to make RAM a peripheral
	- grug huhler's implementation might not be a single cycle CPU - need to check it.
	- we are looking for a new person -we need confirmation by wednesday
- did pin assignments for all input and output of top module
- need to check sda file, and probably add a clock module to reduce 50mhz to 27mhz

### 17 Sep
- i put a pause on running it on FPGA
- trying to run this on a simulator because they want this on a synthesis tool.
- converting all the files into something that can be run on modelsim
- made a new copy of the picorv32 project (as picorv32-sim)
- started learning about systemverilog testbenches and UVM testbench framework
- started making a top_tb.sv
---
- paused work on testbenches, because i forgot to change sram and mem_init -working rn to change sram and meminit to work on modelsim
- when changing from the grug pico to modelsim pico.
	- i want to keep this file structure: top.sv, sram.sv and mem_init.sv

- what im gonna do now:
	- restructure mem_init.sv to be simulator friendly
	- make a python script to convert grug's mem_init.sv to sim mem_init.sv
	- change sram.sv to use this new mem_init.sv while functioning the same way in top.sv
---
- ive given up on trying to use chatgpt to make it for me. ill go through sram.sv and do it myself. ill compile and reformat the c code myself.
---
- i am researching on this sram.v module ([ELI5 SRAM behavior](https://chatgpt.com/c/68cbf088-0d80-8322-92fd-6f1e1352348d)), and a few things are coming to my notice
	- if you want a single cycle cpu, whatever premade SRAM module we're using will need to be async/combinational. 
### 19 Sep
- here's my decisions for the sram.v module
	- read: i will implement both sync and async, and have a compiler directive to pick between the two.
	- read during write: write-through
	- it will have 32-bit aligned addresses. a 13 bit address line, but also a 4 bit wstrb.
	- here's about writestrobes: [RISCV_core - ELI5 SRAM behavior](https://chatgpt.com/c/68cbf088-0d80-8322-92fd-6f1e1352348d)
	- the data itself will be in a hex file and we will load it onto memory using `$readmemh`
- started work on the sram.sv file
	- made async mem read behavior -need to verify using chatgpt
	- working on mem write behavior

#### 26 Sep
- **few questions for prof: why do we use write strobes instead of just direct addresses?**
- [[SRAM implementation verification]]
- writing new sram behavior referred to this: https://chatgpt.com/s/t_68d7695722f481918379c2fe7a6f6adf
### 27 Sep
- ive decided async read would be too complicated to implement because of write through. i am gonna implement only sync read -the mem block will return data 1 cycle after the address is received.
- i made the first iteration, and ik for a fact it's full of misunderstandings. i need to go through [this](https://chatgpt.com/s/t_68d7d3f468a48191bc7ec89bfa873d01) to find required changes
- i read through chatgpt, made some more changes.
- ive realised that i need to make a testbench for this sram.sv module if i wanna develop it any further -because im at a point where everything seems like it will work right, but chatgpt tells me that it will work right logically, even in simulation, but it wont work right on sillicon.
https://chatgpt.com/s/t_68d8366faaa0819195eae2e6e3fca33e

>Nice — you’re very close. Your instinct (make the writes happen into a buffer, then write that into memory, then read memory) is reasonable _in simulation_, but it relies on implementation details and blocking-assignment behaviour that are fragile and can badly mismatch real hardware or synthesis tools. Below I’ll walk through the exact problems (ELI15), why they matter, and give a clean, robust replacement pattern you can drop in.

> ## Quick test ideas to convince yourself
> 
> - Write byte 1 only (`wstrb = 4'b0010`) to address A with data D. Immediately read address A in the same cycle. Expect read to return old_word with byte1 replaced by D[15:8] (merged result) — your testbench should assert this.
>     
> - Try halfword write (`wstrb = 4'b0011`) and verify both bytes changed.
>     
> - Try no-write (`wstrb = 4'b0000`) and ensure read returns the old memory.
>     
> - Run the tests both with the simulator and on FPGA (or with vendor memory model) if possible — behavior should match.

---
- i need to make a testbench for the sram module
- i need to recreate the github repo for this project properly (referring to how i did it for vyadh)

### Oct 5
- reformated the RISCV github page (didnt check the README tho)
	- discovered about worktrees, finally understood how branches work on the directory.

### Oct 9
- reading through chipverify to learn how to make testbenches
	- [SystemVerilog TestBench](https://www.chipverify.com/systemverilog/systemverilog-simple-testbench)
	- [SystemVerilog Testbench Example 1](https://www.chipverify.com/systemverilog/systemverilog-testbench-example-1)
	- [UVM Testbench Example 1](https://www.chipverify.com/uvm/uvm-testbench-example-1)
- taking reference from chatgpt on what files and code blocks to make [RISCV_core - Testbench example guidance](https://chatgpt.com/g/g-p-68c2b3f837f88191bf603055f1e243ba-riscv-core/c/68e6df5e-b3fc-8324-ad5b-657852e18a87)
---
had a meeting with jayakrishnan sir
- he needs to know the specs and usage of UART and timer
- needs to remove modules like LED controller, CDT (probably not CDT)
- needs to add a timer and an interrupt module
- he needs this for his a CDAC meeting which he has tomorrow afternoon

- this CPU probably needs a bus of sorts -everything is connected to everything, there is no bus in the top module
- checkout for the research work done on this: [[UART-Timer-Interrupt_Rev3]]

---
- note: there's this snippet of code in simpleuart.sv that might be useful in making the SRAM:
```
    always @(posedge clk) begin
        if (!resetn) begin
            cfg_divider <= DEFAULT_DIV;
        end else begin
            if (reg_div_we[0]) cfg_divider[ 7: 0] <= reg_div_di[ 7: 0];
            if (reg_div_we[1]) cfg_divider[15: 8] <= reg_div_di[15: 8];
            if (reg_div_we[2]) cfg_divider[23:16] <= reg_div_di[23:16];
            if (reg_div_we[3]) cfg_divider[31:24] <= reg_div_di[31:24];
        end
    end
```
- note: need to get to this point (seeing that command list -which i assume is the cpu displaying all of it's available commands in the sample program) using an FPGA: https://youtu.be/49mK_JVVM_0?list=PL7bIsDBNgNWsOMSPGQcaWWmu-4CNgrxn_&t=447


---
### Oct 12
- we have to look into whether picorv32 is pipelined
- if it is we have to look for alternatives/make our own riscv core
- we need to look into alternatives but oct 13 (monday), if we're modifying by oct 18 (end of the week), and if we're building from scratch -by oct 25 (2 weeks)
- we'll use the comp arch DA
	- we'll have to modify it to boot from the sram, instead of hardcoding the data onto the sram module, i.e, create an sram module
	- let the multiplication be multicycle, instead of making a combinational model
		- afrath and vikas have a multipler already -it takes 18 cycles.
		- few people have done division
	- we'll explore division later
	- we'll need to make an APB bus
- to be done: include SRAM (teusday) > multiplication (teusday) > APB

### Oct 14
- researched about bootloaders -their point. [[Bootloader]]

### Oct 16
- fixed and ran the Basic RISCV32I implementation that i was working on since the beginning. paused picorv32 for a while
- got everything working, but now ive realised that the compiler for the thing broke. im guessing the library im using to compile it has depreciated
- im gonna use an online compiler. but i need to fix this manual compiler somehow

### Oct 17
- updated readme and pushed the changes
- ive realised that the riscv-assembler library is dogshit. i am going to make my own riscv-assembler program.

### Oct 26
- i copy pasted the picrorv32.v file into a folder and decided to blindly start working with it
- i was sick of trying to install linux (for now), so i decided to make my own testbench
- i used testbench_ez.v as a reference and created testbench_0
- after working with testbench_0, i understood the cpu pins (the memory pins mostly) and went back to see how to use testbench_ez
- apparently i just wasnt simulating it long enough. the resetn will wait for 100 clock cycles to go high, and i was simulating for exactly 100 clock cycles.
- so i made resetn wait only for 10 clock cycles to go high, and viola, it worked.
- the simple program in testbench_ez worked and showed an output perfectly.
- next step is to try out the regular testbench and get that working too
---
- i took a guess on what the real testbench does. and apparently, im right:
>here's my guess: you can write a program in C, compile it, assemble it to a hex file, and load it into the testbench (prolly through a destination defined in the makefile). and then the testbench will take it and run the program and probably save the results in the memory in the test bench. and then the memory of the test bench gets dumped into a file that we can read later

> # Your guess — is it correct?
> 
> Yes, essentially:
> - You **write a program** (C or assembly), compile it into a `.hex` (the Makefile does that) and the testbench **loads that hex into simulated memory** (`$readmemh` into `mem.memory`).
> - The testbench runs the core on that memory image.
> - The program can print characters by writing to `0x10000000` (the bench prints them to STDOUT), and can signal success by writing `123456789` to `0x20000000`.
> - The testbench does **not** automatically dump the whole simulated memory to disk by default — but you can add a line to do that (I'll show how).
>
> So your high-level idea is right. The testbench runs the program and provides a memory+IO environment, then reports results.

- here's the progress report im making for the profs [[Progress report]]
- the next step is gonna be to find a way to compile C programs into RISCV assembly

### Oct 29
- made a minimal memory module
- put everything in a top module and im creating a slightly bigger assembly file
- im gonna use this online linker for now: [Online RISC-V Assembler](https://riscvasm.lucasteske.dev/)

- i guess i will be using this online linker for a while. no riscv gcc toolkit for now
- making testbench_1, which will run this file

- the more i work with this the more i realize that everything in HDL is made for linux.

- i finally made the hex file, fixed all problems and compiled
- there seems to be another problem with 

---
- ive realised that it broke probably because i wasnt proper in writing the .data part of the hex file 
- what if it's because im using RV32IC? (`vlog +define+COMPRESSED_ISA ../rtl/picorv32.v`)

- im removing the pseudo instructions to make the code more readable

### Oct 30
- i just realised one thing when i was analysing the waveforms and the linker
```
  MEMORY
  {
    ROM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x10000
    RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 0x08000
  }
```

the memory expects addresses till 8000 -which is a byte address. there are 8000 bytes, so 2000 words

i think the problem all along has been that ive only given it memory till address FFFF. my data is written at 10000. that's what's creating problems. that register doesnt exist. bruh

---
that was an issue, but I'M AN IDIOT, 

```
    always @(posedge clk) begin
        mem_ready <= 0;
        if (mem_valid && !mem_ready) begin
            if (mem_addr < 1024) begin
                mem_ready <= 1;
                mem_rdata <= memory[mem_addr >> 2];
                if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
                if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
                if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
                if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
            end
            /* add memory-mapped IO here */
        end
    end
```

`if (mem_addr < 1024) begin` -the simple_mem module doesnt respond to addresses past 400. bruh. i copied this code block and forgot to change that

>**Short answer:** your program is linked to run at `0x10000` (that's the usual PICORV32 firmware entry/ROM area), but your simple testbench memory only responds to low addresses (`mem_addr < 1024`). The core issues a store to `0x10000`, your testbench ignores that address so `mem_ready` never goes high, and the CPU waits forever (appears to “hang”). The PicoRV32 native memory mapping and reset/start address behaviour are documented in the PicoRV32 README. The mini-SoC example in the repo also expects code/data at `0x10000`.

---
something is wrong. my memory module doesnt take sw instructions. as in it doesnt write when told to.

i need to make a seperate testbench for simple_memory to test it.

### Oct 31
i made a simple testbench for the `simple_mem`.

it puts `0xdeadbeef` onto mem address `0x00010000`

but then when i open the memory map and search for it, i am finding it at memory address 0x00004000

this is some sort of translation error in some module

---
NAH. i got it. 0x10000 / 4 = 0x4000. 

the memory address types out the byte address. the addresses im seeing in questa sim are word addresses. im getting confused between the two. there's nothing wrong with the core nor the memory module.

which means there is no error

---
### Nov 3
instead of APB bus, we can use AXI bus, since it's already supported by picorv32

>A separate core `picorv32_axi_adapter` is provided to bridge between the native memory interface and AXI4. This core can be used to create custom cores that include one or more PicoRV32 cores together with local RAM, ROM, and memory-mapped peripherals, communicating with each other using the native interface, and communicating with the outside world via AXI4.

-picorv32 documentation

so we'll use the picorv32 core + the axi adapter.

---
or so i thought. AXI seems very complex for our use case. but there's another bus protocol called wishbone which is also included in the picorv32 core.

but with wishbone, instead of a memory bus adapter like axi, there is only a direct core implementation of it.

could this overcomplicate things? what even is wishbone master interface?

---

i looked into wb, and:
- wb is much much simpler than axi -and is suitable for
- but the axi implementation is axi4-lite, which is much simpler

- wb would probably be easier to implement as a simple SoC we're making
- but axi would give us much better expansion

essentially, i'd guess wb is kinda analogous to ubuntu, and axi analogous to arch. i think im gonna stick with axi4-lite.

but i do want to look into contributing the the picorv32 project by making a wb adapter. wb itself is an open source protocol unlike axi (made by arm). i wanna start work with axi, learn how it works, and improve on wb

---
following this for axi4-lite: [Welcome to Real Digital](https://www.realdigital.org/doc/a9fee931f7a172423e1ba73f66ca4081)

---
i found a repo with a gpio controller + axi lite wrapper: [pulp-platform/gpio: Parametric GPIO Peripheral](https://github.com/pulp-platform/gpio)

i'm not gonna copy it as it is, since it seems pretty different from the picorv32 project, but ill take inspiration from it

### Nov 8
im working on makin the memory AXI based -partially to learn how to create an AXI device
seems like ill have to relearn FSM to do this the best way

~~[Finite State Machine Explained | Mealy Machine and Moore Machine | What is State Diagram ?](https://www.youtube.com/watch?v=kb-Ww8HaHuE)

~~i think i found a goldmine on axi interface (and wishbone too): [Upcoming topics](https://zipcpu.com/topics.html)

~~and in that site, especially this: [Buidilng an AXI-Lite slave the easy way](https://zipcpu.com/blog/2020/03/08/easyaxil.html)~~

this explains: [What is AXI Lite?](https://www.youtube.com/watch?v=okiTzvihHRA)

everything from dillon huff seems pretty intuitive to learn from. especially the video above. it's very intuitive to learn from. it also explains a bit about write strobes

(a playlist for learning about AXI [What is AXI (Part 1)](https://www.youtube.com/watch?v=1zw1HBsjDH8&list=PLaSdxhHqai2_7WZIhCszu5PLSbZURmibN))

### Nov 11
started work on trying to understand AXI handshake logic: [[AXI]]

i can finally comprehend the read handshake now
### Nov 12
implemented the read logic, and chatgpt says it's error free

tested it with the smoke program and after a small bug fix, it's mostly working

but my program starts off with a write instruction. i can either make a new write program which feels like a pain in the ass. i'll instead implement the write logic and then just run the program as a whole

the logic im following for it: capture -> store -> respond

im gonna develop the write logic independently, as if read logic doesnt exist

then solve the issues like write-through

### Nov 13
picorv32 does not have bresp channel: https://chatgpt.com/share/6915bd24-6818-8007-a167-6cbcdd87d11a

it works. implemented both read and write functionality, fixed a few bugs, and now the memory module works the same as it did with the direct memory bus.

### Nov 14
im gonna implement UART controller now
ill start with making/finding the raw module, and then just connecting it using axi lite

im gonna use the simpleuart.v module from picorv32 only -since it's the simplest to implement

now that im making the axi adapter, i realize that there soooo much optimization to be done

check page 12: [Gowin PicoRV32 Software Programming](https://cdn.gowinsemi.com.cn/IPUG911E.pdf?utm_source=chatgpt.com)
https://chatgpt.com/share/691662a7-3478-8007-ab7a-5b0039cada30

---
bad news: the write function is not working with axi memory. i dont see the data written in 0x00010000

### Nov 18
the culprit was `write_word_index <= (mem_write_addr_buffer - RAM_ORIGIN) >> 2;`

where RAM_ORIGIN is 10000, so when read addr buffer has 10000 in it, it subtracts and word index stays zero, that's why my data gets written in 0x0000

mostly fixed it, but there's still a small problem where the first write happens in 0x0000 instead of 0x4000, and the second write happens in 0x4000 instead of 0x4001 etc.

fixed that also by changing it to a blocking operator so the write word index gets update in this cycle instead of the next cycle

`write_word_index = (mem_write_addr_buffer - RAM_ORIGIN) >> 2;`

---
ive connected up the uart module, made the assembly program and everything is ready. now im finding another issue: BUS connections

>In `top_uart_axi` you connect **two AXI slaves** (`simple_mem_axi` and `simpleuart_axi_adapter`) **directly to the same AXI master wires** coming from `picorv32_axi_adapter` (the `mem_axi_*` signals). That means both slaves see the same AW/AR/W transactions and both may try to drive `*_ready`, `bvalid`, `rvalid`, `rdata`, etc. — bus contention / protocol break. In the working `top_axi` you only hook a single AXI slave (`simple_mem_axi`) to the master, so no conflict.

> Use an off-the-shelf lightweight AXI crossbar / interconnect IP (preferred for clean scaling).

basically two modules are driving the same pins. one module is pulling it high and the other is pulling it low resulting in this: 
![[attachments/Pasted image 20251118164156.png]]

### Dec 10
i'll get to an axi crossbar later on. for now im gonna make an mux that simply lets different modules drive the axi bus based on the

i am trying to use an AXI interface alongside the mux, since there will only be more and more slaves from now onwards. trying to keep the number of repeated lines to as little as possible.

but one caveat -i'd have to modify the memory and uart modules to take interfaces instead of direct modules. this renders the older run.do's useless.

i think for the case of backwards compatibility, i will clone the modules.

---

ive created the code itself, it now contains a mux connecting the two slaves to the master.

---
the uart axi adapter works, but for some reason the simpleuart module itself is not working. ig im using it wrong. im gonna write a seperate testbench to figure out how to use it

### Dec 14
i made a testbench for simpleuart and realised a few things
- the module can only transmitt 8 bits at a time. even tho dat_di is 32 bits, only the first 8 bits get transmitted
- the rest ive written in the code itself

and things i realised when writing the axi uart adapter:
- https://chatgpt.com/share/693f64e9-2020-8007-b7e5-4769ddb005f7
	- watchout for send_dummy activity inside uart

### Dec 15
got uart tx. but now there's another issue. there is no buffering. the core doesnt know when it can send the next byte for transmission, so it just bombards the uart module with tx/rx commands without any response from the module. the simplest solution to this is to add an extra register to the simpleuart module that is directly or inversely connected to dat_wait. this is possibly also the only solution since if you were to buffer, how many buffer registers could you have before you come back to square one of having to wait till transmission completes? but this also feels like a lazy solution

im looking at alternatives

---
that is exactly what i ended up doing. i reused `!0x00[0]` as a flag register (TX_READY) and rewrote the program to send bytes only when the flag is high. it works now.

### Dec 25
we need to get the SoC verified and ready to send for external verification. the pico core itself is all good. the simple mem will be replaced by a macro. the uart module is also very basic, and probably pre tested. it's only the axi lite implementation that we did ourselves. here's a list of everything that we need to do before the year ends, so that we can send ts for verification on jan.
- create a better and a more optimized AXI lite adapter.
- implement a GPIO module
- look into alternatives to a mux for having multiple AXI slaves.

---
before that, i need to restructure the github repo, because i learnt how to use git better.