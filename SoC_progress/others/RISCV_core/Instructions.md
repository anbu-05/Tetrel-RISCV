![[Pasted image 20251016155542.png]]

## Registers
| Register | ABI Name | Description           | Saver  |
| -------- | -------- | --------------------- | ------ |
| x0       | zero     | Zero constant         | —      |
| x1       | ra       | Return address        | Callee |
| x2       | sp       | Stack pointer         | Callee |
| x3       | gp       | Global pointer        | —      |
| x4       | tp       | Thread pointer        | —      |
| x5–x7    | t0–t2    | Temporaries           | Caller |
| x8       | s0 / fp  | Saved / frame pointer | Callee |
| x9       | s1       | Saved register        | Callee |
| x10–x11  | a0–a1    | Fn args/return values | Caller |
| x12–x17  | a2–a7    | Fn args               | Caller |
| x18–x27  | s2–s11   | Saved registers       | Callee |
| x28–x31  | t3–t6    | Temporaries           | Caller |
| f0–f7    | ft0–ft7  | FP temporaries        | Caller |
| f8–f9    | fs0–fs1  | FP saved registers    | Callee |
| f10–f11  | fa0–fa1  | FP args/return values | Caller |
| f12–f17  | fa2–fa7  | FP args               | Caller |
| f18–f27  | fs2–fs11 | FP saved registers    | Callee |
| f28–f31  | ft8–ft11 | FP temporaries        | Caller |


## RV32I base Integer Instructions
| Inst   | Name                    | FMT | Description (C)                          | Note         | status |
| ------ | ----------------------- | --- | ---------------------------------------- | ------------ | ------ |
| add    | ADD                     | R   | rd = rs1 + rs2                           |              |        |
| sub    | SUB                     | R   | rd = rs1 - rs2                           |              |        |
| xor    | XOR                     | R   | rd = rs1 ^ rs2                           |              |        |
| or     | OR                      | R   | rd = rs1 \| rs2                          |              |        |
| and    | AND                     | R   | rd = rs1 & rs2                           |              |        |
| sll    | Shift Left Logical      | R   | rd = rs1 << rs2                          |              |        |
| srl    | Shift Right Logical     | R   | rd = rs1 >> rs2                          | msb-extends  |        |
| sra    | Shift Right Arithmetic  | R   | rd = rs1 >> rs2                          | msb-extends  |        |
| slt    | Set Less Than           | R   | rd = (rs1 < rs2)? 1 : 0                  |              |        |
| sltu   | Set Less Than (U)       | R   | rd = (rs1 < rs2)? 1 : 0                  | zero-extends |        |
| addi   | ADD Immediate           | I   | rd = rs1 + imm                           |              |        |
| xori   | XOR Immediate           | I   | rd = rs1 ^ imm                           |              |        |
| ori    | OR Immediate            | I   | rd = rs1 \| imm                          |              |        |
| andi   | AND Immediate           | I   | rd = rs1 & imm                           |              |        |
| slli   | Shift Left Logical Imm  | I   | rd = rs1 << imm[0:4]                     |              |        |
| srli   | Shift Right Logical Imm | I   | rd = rs1 >> imm[0:4]                     |              |        |
| srai   | Shift Right Arith Imm   | I   | rd = rs1 >> imm[0:4]                     | msb-extends  |        |
| slti   | Set Less Than Imm       | I   | rd = (rs1 < imm)? 1 : 0                  |              |        |
| sltiu  | Set Less Than Imm (U)   | I   | rd = (rs1 < imm)? 1 : 0                  | zero-extends |        |
| lb     | Load Byte               | I   | rd = M[rs1 + imm][0:7]                   |              |        |
| lh     | Load Half               | I   | rd = M[rs1 + imm][0:15]                  |              |        |
| lw     | Load Word               | I   | rd = M[rs1 + imm][0:31]                  |              |        |
| lbu    | Load Byte (U)           | I   | rd = M[rs1 + imm][0:7]                   | zero-extends |        |
| lhu    | Load Half (U)           | I   | rd = M[rs1 + imm][0:15]                  | zero-extends |        |
| sb     | Store Byte              | S   | M[rs1 + imm][0:7] = rs2[0:7]             |              |        |
| sh     | Store Half              | S   | M[rs1 + imm][0:15] = rs2[0:15]           |              |        |
| sw     | Store Word              | S   | M[rs1 + imm][0:31] = rs2[0:31]           |              |        |
| beq    | Branch ==               | B   | if(rs1 == rs2) PC += imm                 |              |        |
| bne    | Branch !=               | B   | if(rs1 != rs2) PC += imm                 |              |        |
| blt    | Branch <                | B   | if(rs1 < rs2) PC += imm                  |              |        |
| bge    | Branch ≥                | B   | if(rs1 ≥ rs2) PC += imm                  |              |        |
| bltu   | Branch < (U)            | B   | if(rs1 < rs2) PC += imm                  | zero-extends |        |
| bgeu   | Branch ≥ (U)            | B   | if(rs1 ≥ rs2) PC += imm                  | zero-extends |        |
| jal    | Jump and Link           | J   | rd = PC + 4; PC += imm                   |              |        |
| jalr   | Jump and Link Reg       | I   | rd = PC + 4; PC = rs1 + imm              |              |        |
| lui    | Load Upper Imm          | U   | rd = imm << 12                           |              |        |
| auipc  | Add Upper Imm to PC     | U   | rd = PC + (imm << 12)                    |              |        |
| ecall  | Environment Call        | I   | imm = 0x0 → Transfer control to OS       |              |        |
| ebreak | Environment Break       | I   | imm = 0x1 → Transfer control to debugger |              |        |

## RV32M Multiply Extension
| Inst  | Name            | FMT | Description (C)         | status |
| ----- | --------------- | --- | ----------------------- | ------ |
| mul   | MUL             | R   | rd = (rs1 * rs2)[31:0]  |        |
| mulh  | MUL High        | R   | rd = (rs1 * rs2)[63:32] |        |
| mulsu | MUL High (S)(U) | R   | rd = (rs1 * rs2)[63:32] |        |
| mulu  | MUL High (U)    | R   | rd = (rs1 * rs2)[63:32] |        |
| div   | DIV             | R   | rd = rs1 / rs2          |        |
| divu  | DIV (U)         | R   | rd = rs1 / rs2          |        |
| rem   | Remainder       | R   | rd = rs1 % rs2          |        |
| remu  | Remainder (U)   | R   | rd = rs1 % rs2          |        |
