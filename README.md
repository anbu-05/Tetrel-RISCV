# Tetrel-RISCV

Tetrel-RISCV is an RV32IM SoC built around the `picorv32` core. The project focuses on clarity and correctness first, with simulation-driven development using QuestaSim.

## Overview

Main directory: `/Tetrel-RISCV/`

Folder structure:

```
/Tetrel-RISCV/
├─ SoC/
│  ├─ hex/               # Hex files loaded into memory
│  │  └─ prog/           # Assembly programs corresponding to hex files
│  ├─ rtl/               # SoC RTL (core, bus, peripherals)
│  ├─ tb/                # Testbench files
│  └─ sim/               # Questa simulation setup (run.do, configs)
├─ linker.ld             # Linker script
├─ README.md
└─ old/                  # Deprecated / archived work
```

The SoC is simulated using Intel/Altera QuestaSim.

---

## Tooling Notes

Program assembly and verification are currently done using lightweight external tools:

- [RISC-V Online Assembler -racerxdl](https://riscvasm.lucasteske.dev/#)
    - [github repo](https://github.com/racerxdl/riscv-online-asm)
- [RISC-V Instruction Encoder / Decoder -LupLab](https://luplab.gitlab.io/rvcodecjs/#q=40628433&abi=false&isa=AUTO)
- [RISC-V ISA Reference -lhtin](https://lhtin.github.io/01world/app/riscv-isa/?xlen=32)
    - [github repo](https://github.com/lhtin/01world/tree/main/app/riscv-isa-dev)

These tools are used for validation and experimentation during development. Generated `.hex` files are checked into the repository to ensure reproducible simulation results.

---

## Running the SoC

1. Open a terminal in:

   ```
   Tetrel-RISCV/SoC/sim/
   ```

2. Open `run.do` and edit waveform selections if needed.

   **Important:** make sure the simulation is launched with:

   ```
   -voptargs="+acc"
   ```

   Without this, Questa may not expose internal signals and memory correctly.

3. Place your program hex file in:

   ```
   Tetrel-RISCV/SoC/hex/
   ```

4. The memory is initialized in `simple_mem.sv`. Update the hex filename if required:

   ```verilog
   initial $readmemh("../hex/smoke_test.hex", memory);
   ```

5. Launch QuestaSim:

   ```bash
   vsim &
   ```

6. Inside Questa, confirm the working directory:

   ```tcl
   pwd
   ```

   It should be:

   ```
   Tetrel-RISCV/SoC/sim
   ```

7. Run the simulation:

   ```tcl
   do run.do
   ```

The SoC should now reset, execute the program, and expose activity on the bus, memory, and peripherals (UART, etc.).

---

## Writing and Running Programs

Assembly source files live in:

```
SoC/hex/prog/
```

Generated `.hex` files are stored in:

```
SoC/hex/
```

Hex files are checked into the repo to ensure deterministic simulation results.

### Notes on Writing Assembly

* Instructions are **word-aligned** (4 bytes)
* Program execution starts at address `0x00000000`
* Branch and jump immediates follow standard RISC-V encoding rules
* `lui` loads the immediate into bits `[31:12]` (`imm << 12`)

Keeping track of instruction addresses in comments is highly recommended during development:

```assembly
addi x1, x0, 10      ; addr = 0
addi x2, x0, 15      ; addr = 4
add  x3, x1, x2      ; addr = 8
sw   x3, 0(x0)       ; addr = 12
```

This makes waveform-level debugging much easier.

---

## Memory Map

```
ROM   : 0x00000000 – 0x0000FFFF  (64 KiB)
RAM   : 0x00010000 – 0x00017FFF  (32 KiB)
UART  : 0x00018000 – 0x00018008
GPIO  : 0x00018100 – undefined
```

> note: Instruction fetch currently comes from RAM; ROM is used as general data storage.

### UART Registers

```
0x00 : FLAGS
       [0] TX_READY
0x04 : CLKDIV (32-bit)
0x08 : DATA   (32-bit)
```

* Registers are **word-addressable**
* `DATA` supports byte writes (`sb`) for transmission

---

## Notes and Limitations

* No interrupt support yet
* No CSR handling
* Peripheral set is intentionally minimal
* Design favors readability and explicit structure over performance optimizations
