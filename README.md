# Tetrel-RISCV
this is a RV32IM SoC built around the picorv32 core. it is currently under development

NOTE: i recreated this project to fit a new project structure (after learning a bit more on how to use git). you can find the depreciated repo here: [RISCV_project](https://github.com/anbu-05/RISCV_project)

## Overview

Main directory: `/RISCV_SoC/`

Folder structure:

```
/RISCV_SoC/
├─ RISCV_core/           # Main CPU design
│  ├─ hex/               # hex files to be loaded onto memory
│  │  └─ prog/           # the assembly files corresponding to hex files
│  ├─ rtl/               # Design (ALU, RegisterFile, Decoder, etc.)
│  ├─ tb/                # Testbench files
│  └─ sim/               # Questa simulation setup (run.do and configs)
├─ README.md
└─ old/                  # older work files
```

The core was built using Intel/Altera QuestaSim.

to assemble and link the programs, so far ive been using this [RISC-V Online Assembler](https://riscvasm.lucasteske.dev/#) and some chatgpt

to verify individual commands, i use this [RISC-V Instruction Encoder/Decoder](https://luplab.gitlab.io/rvcodecjs/#q=40628433&abi=false&isa=AUTO)

## Memory mapping
    - ROM = 32'h00000000 to 32'h0000FFFF, (64 KiB) -Data memory
    - RAM = 32'h00010000 to 32'h00017FFF (32 KiB) -Instruction memory
    - UART = 32'h00018000 to 32'h00018008 -simpleuart control registers
    - GPIO = 32'h00018100 to undefined

note: uart control registers:
```
0x00 : FLAGS
    [0]: TX_READY
0x04 : CLKDIV (32-bit)
0x08 : DATA   (32-bit)
```
