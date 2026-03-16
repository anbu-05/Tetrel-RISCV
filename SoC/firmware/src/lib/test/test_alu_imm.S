# test_alu_imm.S
# Tests: ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU
# Returns 1 in a0 if all pass, 0 if any fail

.section .text
.global test_alu_imm

test_alu_imm:

    # ADDI: 10 + 5 = 15
    li a1, 10
    addi a2, a1, 5
    li a3, 15
    bne a2, a3, alu_imm_fail

    # ANDI: 0xFF & 0x0F = 0x0F
    li a1, 0xFF
    andi a2, a1, 0x0F
    li a3, 0x0F
    bne a2, a3, alu_imm_fail

    # ORI: 0xF0 | 0x0F = 0xFF
    li a1, 0xF0
    ori  a2, a1, 0x0F
    li a3, 0xFF
    bne a2, a3, alu_imm_fail

    # XORI: 0xFF ^ 0x0F = 0xF0
    li a1, 0xFF
    xori a2, a1, 0x0F
    li a3, 0xF0
    bne a2, a3, alu_imm_fail

    # SLLI: 1 << 3 = 8
    li a1, 1
    slli a2, a1, 3
    li a3, 8
    bne a2, a3, alu_imm_fail

    # SRLI: 32 >> 2 = 8 (logical)
    li a1, 32
    srli a2, a1, 2
    li a3, 8
    bne a2, a3, alu_imm_fail

    # SRAI: -32 >> 2 = -8 (arithmetic)
    li a1, -32
    srai a2, a1, 2
    li a3, -8
    bne a2, a3, alu_imm_fail

    # SLTI: 3 < 10 = 1 (signed)
    li a1, 3
    slti a2, a1, 10
    li a3, 1
    bne a2, a3, alu_imm_fail

    # SLTIU: 3 < 10 = 1 (unsigned)
    li a1, 3
    sltiu a2, a1, 10
    li a3, 1
    bne a2, a3, alu_imm_fail

    li a0, 1        # all passed
    ret

alu_imm_fail:
    li a0, 0
    ret
