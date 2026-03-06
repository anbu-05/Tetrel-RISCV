# Tetrel-RISCV

Tetrel-RISCV is an RV32IMC SoC built around the `picorv32` core. The project focuses on clarity and correctness first, with simulation-driven development using QuestaSim and Xcelium.

## Overview

Main directory: `/Tetrel-RISCV/`

Folder structure:

```
/Tetrel-RISCV/
├─ SoC/
│  ├─ firmware/          # C firmware for the SoC
│  │  ├─ src/            # C source files
│  │  ├─ asm/            # start.S (startup code)
│  │  ├─ build/          # Intermediate files (.o, .elf)
│  │  ├─ hex/            # Final .hex outputs loaded by simplemem
│  │  ├─ linker.ld       # Linker script
│  │  └─ Makefile        # Build system
│  ├─ sourcecode/
│  │  └─ rtl/            # SoC RTL (core, bus, peripherals)
│  ├─ sim/               # Simulation setup (run.do, configs)
│  └─ tb/                # Testbench files
├─ README.md
└─ SoC_progress/         # Progress log
```

---

## Toolchain

Install the RISC-V GCC toolchain:

```bash
sudo apt install gcc-riscv64-unknown-elf
```

- Compiler: `riscv64-unknown-elf-gcc`
- Target arch: `RV32IMC` (`-march=rv32imc -mabi=ilp32`)

### Building firmware

```bash
cd SoC/firmware
make
```

This compiles your C program and produces a `.hex` file in `SoC/firmware/hex/`.

### Manual compile commands

```bash
# Compile to ELF
riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -nostdlib \
  -T linker.ld -o build/smoke_test.elf asm/start.S src/smoke_test.c

# Convert ELF to HEX
riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 \
  build/smoke_test.elf hex/smoke_test.hex && \
awk '/^@/{print; next} {for(i=1;i<=NF;i++) print $i}' \
  hex/smoke_test.hex > hex/smoke_test.hex.tmp && \
mv hex/smoke_test.hex.tmp hex/smoke_test.hex
```

---

## Tooling Notes

For low-level validation and experimentation:

- [RISC-V Online Assembler - racerxdl](https://riscvasm.lucasteske.dev/#)
    - [github repo](https://github.com/racerxdl/riscv-online-asm)
- [RISC-V Instruction Encoder / Decoder - LupLab](https://luplab.gitlab.io/rvcodecjs/#q=40628433&abi=false&isa=AUTO)
- [RISC-V ISA Reference - lhtin](https://lhtin.github.io/01world/app/riscv-isa/?xlen=32)
    - [github repo](https://github.com/lhtin/01world/tree/main/app/riscv-isa-dev)

You can find a progress log in [/SoC_progress/progress/Progress.md](https://github.com/anbu-05/Tetrel-RISCV/blob/main/SoC_progress/progress/Progress.md)

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
   Tetrel-RISCV/SoC/firmware/hex/
   ```

4. The hex filename is set in `top.sv`:

   ```systemverilog
   simplemem #(
       .PROGRAM_HEX("../firmware/hex/smoke_test.hex")
   ) mem ( ... );
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

---

## Memory Map

```
ROM   : 0x00000000 – 0x0000FFFF  (64 KiB)  program code
RAM   : 0x00010000 – 0x00017FFF  (32 KiB)  stack and variables
UART  : 0x00018000 – 0x0001800B  (12 B)    serial UART
GPIO  : 0x00020000 – 0x00020007  (8 B)     general purpose I/O
```

Program execution starts at `0x00000000`.

---

## UART Registers (`0x00018000`)

| Offset | Name   | Description                                      |
|--------|--------|--------------------------------------------------|
| `+0x0` | DIV    | Baud rate divisor. `divisor = clk_freq / baud`  |
| `+0x4` | DAT    | Write: TX byte. Read: RX byte                   |
| `+0x8` | STATUS | Bit 0 = TX busy (1 = busy, wait before writing) |

**Baud rate examples:**

| Clock    | Baud    | Divisor |
|----------|---------|---------|
| 50 MHz   | 115200  | 434     |
| 50 MHz   | 9600    | 5208    |
| 1 MHz    | 115200  | 8       |

> In simulation you can set `DIV = 1` so each UART bit takes 1 clock cycle. This makes UART output fast to simulate but won't work on real hardware.

---

## GPIO Registers (`0x00020000`)

| Offset | Name | Description                                         |
|--------|------|-----------------------------------------------------|
| `+0x0` | DATA | Write: output pin values. Read: current pin state   |
| `+0x4` | DIR  | Pin direction per bit. `1` = output, `0` = input    |

**Notes:**
- On reset all pins default to input (`DIR = 0`)
- Always set `DIR` before writing `DATA`
- Reading `DATA` on an output pin returns the value you wrote
- Reading `DATA` on an input pin returns the value on the physical pin

---

## Writing Firmware in C

A minimal C program for this SoC needs two files alongside your `.c` source:

**`asm/start.S`** — runs before `main()`, sets up the stack:
```asm
.section .text
.global _start

_start:
    la sp, _stack_top
    call main

loop:
    j loop
```

**`linker.ld`** — tells the linker where to place code and data in memory:
```
ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K   ← code
RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 32K   ← stack, variables
```

---

## Notes and Limitations

- No interrupt support yet
- No CSR handling
- Peripheral set is intentionally minimal
- Design favors readability and explicit structure over performance