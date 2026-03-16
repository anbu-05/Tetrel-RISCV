# test_alu_reg.S
# Tests: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
# Returns 1 in a0 if all pass, 0 if any fail

.section .text
.global test_alu_reg

test_alu_reg:
    li t0, 0        # t0 = fail flag, becomes 1 on any failure

    # ADD: 10 + 20 = 30
    li a1, 10
    li a2, 20
    add a3, a1, a2
    li a4, 30
    bne a3, a4, alu_reg_fail

    # SUB: 50 - 8 = 42
    li a1, 50
    li a2, 8
    sub a3, a1, a2
    li a4, 42
    bne a3, a4, alu_reg_fail

    # AND: 0xFF & 0x0F = 0x0F
    li a1, 0xFF
    li a2, 0x0F
    and a3, a1, a2
    li a4, 0x0F
    bne a3, a4, alu_reg_fail

    # OR: 0xF0 | 0x0F = 0xFF
    li a1, 0xF0
    li a2, 0x0F
    or  a3, a1, a2
    li a4, 0xFF
    bne a3, a4, alu_reg_fail

    # XOR: 0xFF ^ 0x0F = 0xF0
    li a1, 0xFF
    li a2, 0x0F
    xor a3, a1, a2
    li a4, 0xF0
    bne a3, a4, alu_reg_fail

    # SLL: 1 << 4 = 16
    li a1, 1
    li a2, 4
    sll a3, a1, a2
    li a4, 16
    bne a3, a4, alu_reg_fail

    # SRL: 16 >> 2 = 4 (logical, no sign extension)
    li a1, 16
    li a2, 2
    srl a3, a1, a2
    li a4, 4
    bne a3, a4, alu_reg_fail

    # SRA: -16 >> 2 = -4 (arithmetic, sign extended)
    li a1, -16
    li a2, 2
    sra a3, a1, a2
    li a4, -4
    bne a3, a4, alu_reg_fail

    # SLT: 5 < 10 = 1 (signed)
    li a1, 5
    li a2, 10
    slt a3, a1, a2
    li a4, 1
    bne a3, a4, alu_reg_fail

    # SLTU: 5 < 10 = 1 (unsigned)
    li a1, 5
    li a2, 10
    sltu a3, a1, a2
    li a4, 1
    bne a3, a4, alu_reg_fail

    li a0, 1        # all passed
    ret

alu_reg_fail:
    li a0, 0
    ret
