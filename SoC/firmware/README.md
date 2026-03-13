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
| 0 | ALU Register | `ADD` `SUB` `AND` `OR` `XOR` `SLL` `SRL` `SRA` `SLT` `SLTU` |
| 1 | ALU Immediate | `ADDI` `ANDI` `ORI` `XORI` `SLLI` `SRLI` `SRAI` `SLTI` `SLTIU` |
| 2 | Load | `LW` `LH` `LB` `LHU` `LBU` |
| 3 | Store | `SW` `SH` `SB` |
| 4 | Branch | `BEQ` `BNE` `BLT` `BGE` `BLTU` `BGEU` |
| 5 | Jump | `JAL` `JALR` |
| 6 | Upper Immediate | `LUI` `AUIPC` |
| 7 | M-extension | `MUL` `MULH` `MULHU` `MULHSU` `DIV` `DIVU` `REM` `REMU` |
| 8 | C-extension | `C.LI` `C.MV` `C.ADD` `C.ADDI` `C.SW` `C.LW` `C.BEQZ` `C.J` |

#### Methodology

**ALU tests (slots 0 and 1):** Each instruction is given two known operands. The result is compared against a hardcoded expected value. A single mismatch fails the entire group.

**Load/Store tests (slots 2 and 3):** A known word (`0xAABBCCDD`) is written to a scratch area on the stack. Each load variant reads it back and checks the result, including sign extension behaviour for `LB` and `LH`. Store tests write using each store variant then read back with a full-width `LW` or unsigned load to confirm only the intended bytes were modified.

**Branch tests (slot 4):** Each branch instruction is tested twice — once where the branch *should* be taken, and once where it *should not* be taken. A fall-through to a fail label covers incorrect behaviour in both directions.

**Jump tests (slot 5):** `JAL` and `JALR` are tested by jumping to a target label and verifying that `ra` was written with the correct return address before returning.

**Upper immediate tests (slot 6):** `LUI` is checked by comparing the result against the expected shifted immediate. `AUIPC` is verified by checking that the result falls within the expected ROM address range, since the exact PC value is not known at compile time.

**M-extension tests (slot 7):** Each multiply and divide instruction is given operands with known results, including edge cases: upper-half results for `MULH`/`MULHU`/`MULHSU`, and signed vs unsigned variants for `DIV`/`REM`.

**C-extension tests (slot 8):** A hand-picked subset of compressed instructions are explicitly encoded using assembler mnemonics (`c.li`, `c.mv`, etc.) to confirm the CPU decodes compressed opcodes correctly. Behaviour is verified the same way as the ALU tests — known inputs, expected outputs.

#### File structure

```
firmware/
├── makefile
├── README.md
├── src/
│   ├── unit_test_instr.c       # main: calls test functions, writes signatures
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
│       └── test_c_ext.S
├── linker.ld
├── .last_build                 # file required for makefile
├── hex/                        # compiled hex files live here
├── build/                      # build files during compilation
├── bootloader/                 # the bootloader lives here
```