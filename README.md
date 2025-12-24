# Tetrel-RISCV
this is a RV32IM SoC built around the picorv32 core. it is currently under development

## Overview

Main directory: `/RISCV_SoC/`

Folder structure:

```
/RISCV_SoC/
├─ RISCV_core/           # Main CPU design
│  ├─ programs/          # hex files to be loaded onto memory
│  ├─ rtl/               # Design (ALU, RegisterFile, Decoder, etc.)
│  ├─ tb/                # Testbench files
│  └─ sim/               # Questa simulation setup (run.do and configs)
├─ README.md
└─ old/                  # older work files
```

The core was built using Intel/Altera QuestaSim.

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
