# Tetrel-RISCV Firmware Tests

This document describes the unit tests for the Tetrel-RISCV SoC firmware.  
All tests share the same signature-based verification framework. The testbench watches for `SIG_DONE` and prints all slot results — it has no knowledge of what each slot means; that is defined entirely by the test program.

For full details on the signature framework, see the SoC-level README.

---

## How to run a test

```bash
make <test_name>
```

This compiles the firmware, generates a hex file, and places it at `hex/program.hex`.  
Load that hex into the simulator as usual.

---

## Tests

### `smoke_test`

**File:** `src/smoke_test.c`  
**Run:** `make smoke_test`

A basic sanity check that confirms the core SoC subsystems are alive. It does not exhaustively verify instructions — it just checks that the CPU can do arithmetic, the multiplier works, UART can transmit a byte, and GPIO readback works correctly. Intended as a quick go/no-go before running deeper tests.

| Slot | What it checks |
|------|----------------|
| 0    | CPU ADD: `10 + 20 == 30` |
| 1    | CPU MUL: `6 * 7 == 42` |
| 2    | UART TX: byte `0x41` transmitted without hang |
| 3    | GPIO readback: write `0xAAAAAAAA`, read back same value |

---

### `instr_test`

**Files:** `src/unit_test_instr.c` + `src/asm/test_*.S`  
**Run:** `make instr_test`

Exhaustive instruction-level unit test for the RV32IMC ISA. Each instruction is exercised with known input values and the result is compared against a precomputed expected value. Tests are written in assembly (`.S` files) so that specific instructions can be encoded explicitly, without relying on the compiler to emit them. The C file (`unit_test_instr.c`) owns the signature logic and calls each assembly test function.

Each assembly test function returns `1` (pass) or `0` (fail) in `a0`. The C file maps each return value to a signature slot.

#### Slot assignments

| Slot | Group | Instructions tested |
|------|-------|---------------------|
| 0  | ALU Register          | `ADD` `SUB` `AND` `OR` `XOR` `SLL` `SRL` `SRA` `SLT` `SLTU` |
| 1  | ALU Immediate         | `ADDI` `ANDI` `ORI` `XORI` `SLLI` `SRLI` `SRAI` `SLTI` `SLTIU` |
| 2  | Load                  | `LW` `LH` `LB` `LHU` `LBU` |
| 3  | Store                 | `SW` `SH` `SB` |
| 4  | Branch                | `BEQ` `BNE` `BLT` `BGE` `BLTU` `BGEU` |
| 5  | Jump                  | `JAL` `JALR` |
| 6  | Upper Immediate       | `LUI` `AUIPC` |
| 7  | M-extension           | `MUL` `MULH` `MULHU` `MULHSU` `DIV` `DIVU` `REM` `REMU` |
| 8  | C-extension ALU       | `C.NOP` `C.ADDI` `C.ADDI16SP` `C.ADDI4SPN` `C.LI` `C.LUI` `C.MV` `C.ADD` `C.AND` `C.OR` `C.XOR` `C.SUB` `C.SLLI` `C.SRLI` `C.SRAI` `C.ANDI` |
| 9  | C-extension Load/Store| `C.LW` `C.SW` `C.LWSP` `C.SWSP` |
| 10 | C-extension Branch    | `C.BEQZ` `C.BNEZ` |
| 11 | C-extension Jump      | `C.J` `C.JAL` `C.JR` `C.JALR` |
| 12 | Trap / System         | `ECALL` `EBREAK` `C.EBREAK` |

#### Methodology

**ALU tests (slots 0 and 1):** Each instruction is given two known operands. The result is compared against a hardcoded expected value. A single mismatch fails the entire group.

**Load/Store tests (slots 2 and 3):** A known word (`0xAABBCCDD`) is written to a scratch area on the stack. Each load variant reads it back and checks the result, including sign extension behaviour for `LB` and `LH`. Store tests write using each store variant then read back with a full-width `LW` or unsigned load to confirm only the intended bytes were modified.

**Branch tests (slot 4):** Each branch instruction is tested twice — once where the branch *should* be taken, and once where it *should not* be taken. A fall-through to a fail label covers incorrect behaviour in both directions.

**Jump tests (slot 5):** `JAL` and `JALR` are tested by jumping to a target label, setting a flag at the target to confirm it was reached, and returning via `ra`. Correct `ra` is proven implicitly — if execution returns to the right place, the link was correct.

**Upper immediate tests (slot 6):** `LUI` is checked by comparing the result against the expected shifted immediate. `AUIPC` is verified by checking that the result falls within the expected ROM address range, since the exact PC value is not known at compile time.

**M-extension tests (slot 7):** Each multiply and divide instruction is given operands with known results, including edge cases: upper-half results for `MULH`/`MULHU`/`MULHSU`, and signed vs unsigned variants for `DIV`/`REM`. Requires `ENABLE_MUL=1` and `ENABLE_DIV=1` on the PicoRV32 instance.

**C-extension ALU tests (slot 8):** All 16 compressed ALU instructions are tested with known operands and expected results, following the same pattern as the base ALU tests. `C.NOP` is verified by confirming it does not hang.

**C-extension Load/Store tests (slot 9):** `C.LW`/`C.SW` use a CIW register (`s0`) as the base since `sp` is not valid for these forms. `C.LWSP`/`C.SWSP` use `sp` directly. Known values are written and read back.

**C-extension Branch tests (slot 10):** `C.BEQZ` and `C.BNEZ` are each tested taken and not-taken, same methodology as the base branch tests.

**C-extension Jump tests (slot 11):** `C.J`, `C.JAL`, `C.JR`, `C.JALR` are tested by jumping to a target, setting a flag, and returning. `C.J` has no link register so the target returns via a register loaded with the return address.

**Trap / System tests (slot 12):** `ECALL`, `EBREAK`, and `C.EBREAK` are tested by temporarily installing a custom handler into the relevant vector table slot. The handler sets a flag in RAM, increments `mepc` by 4 to skip past the trapping instruction, then returns via `mret`. The test checks the flag after each trap. Vector table slots are restored to `default_handler` after each test. Requires `ENABLE_IRQ=1` and `ENABLE_IRQ_QREGS=0` on the PicoRV32 instance.

#### Instructions not covered

`FENCE` executes as a NOP on PicoRV32 (no cache, no out-of-order execution) so there is no result to verify beyond confirming it does not hang. It is omitted from the test.

#### File structure

```
firmware/
├── makefile
├── README.md
├── linker.ld
├── bootloader/
│   └── start.s
├── src/
│   ├── unit_test_instr.c
│   ├── smoke_test.c
│   └── asm/
│       ├── test_alu_reg.S
│       ├── test_alu_imm.S
│       ├── test_load.S
│       ├── test_store.S
│       ├── test_branch.S
│       ├── test_jump.S
│       ├── test_upper.S
│       ├── test_m.S
│       ├── test_c_alu.S
│       ├── test_c_loadstore.S
│       ├── test_c_branch.S
│       ├── test_c_jump.S
│       └── test_trap.S
├── hex/
├── build/
└── .last_build
```

---

## Bootloader & Trap System

The bootloader lives in `bootloader/start.s` and runs before `main()` on every reset. It handles two things: stack initialisation and trap system setup.

### ROM layout

| Address | Contents |
|---------|----------|
| `0x00000000` | `_start` — stack init, vector table init, call main |
| `0x00000100` | `trap_entry` — trap dispatcher (`PROGADDR_IRQ`) |
| `0x00000200` | `default_handler` — built-in halt handler |

256 bytes are reserved between `_start` and `trap_entry` for future bootloader expansion (SPI flash, UART firmware load, etc.).

### Trap system

When a trap fires (ECALL, EBREAK, illegal instruction, misaligned access), the CPU jumps to `trap_entry` at `0x00000100`. The dispatcher reads `mcause` to identify the cause, then looks up the corresponding slot in the vector table in RAM and jumps to whatever address is stored there.

By default all slots point to `default_handler`. User code can overwrite any slot at runtime to install a custom handler for that trap type.

### Vector table (RAM, `0x00010000`)

Five 4-byte slots, initialised by `_start` before `main()` is called:

| Address | Slot | Default | mcause |
|---------|------|---------|--------|
| `0x00010000` | `vector_ecall` | `default_handler` | 8 / 11 |
| `0x00010004` | `vector_ebreak` | `default_handler` | 3 |
| `0x00010008` | `vector_illegal` | `default_handler` | 2 |
| `0x0001000C` | `vector_misalign` | `default_handler` | 0 |
| `0x00010010` | `vector_panic` | `0x00000000` (null) | — |

`vector_panic` is special — it is not dispatched to directly. Instead, `default_handler` checks it before halting. If it is nonzero, `default_handler` jumps there instead of halting. This gives user code a single catch-all hook for any unhandled trap.

### Installing a custom handler

Write the address of your handler function to the relevant slot before the trap can fire:

```c
// redirect ECALL to your own handler
*(volatile unsigned int *)0x00010000 = (unsigned int)my_ecall_handler;

// catch all unhandled traps
*(volatile unsigned int *)0x00010010 = (unsigned int)my_panic_handler;
```

### default_handler behaviour

If `vector_panic` is null (the default), `default_handler` halts in an infinite loop (`halt: j halt`). To diagnose a trap, overwrite `vector_panic` with a handler that inspects `mcause` and any other state you need.

### Required SoC parameters

The trap system requires these parameters on the PicoRV32 instantiation in `top.sv`:

```systemverilog
.ENABLE_IRQ       (1),
.ENABLE_IRQ_QREGS (0),
.PROGADDR_IRQ     (32'h00000100)
```