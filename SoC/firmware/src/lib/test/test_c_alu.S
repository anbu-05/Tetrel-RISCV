# test_c_alu.S
# Tests all C-extension ALU instructions:
#   C.NOP, C.ADDI, C.ADDI16SP, C.ADDI4SPN, C.LI, C.LUI,
#   C.MV, C.ADD, C.AND, C.OR, C.XOR, C.SUB,
#   C.SLLI, C.SRLI, C.SRAI, C.ANDI
# Returns 1 in a0 if all pass, 0 if any fail

.section .text
.global test_c_alu

test_c_alu:
    addi sp, sp, -16
    sw ra, 0(sp)

    # C.NOP: does nothing, just confirm it doesn't hang
    c.nop

    # C.LI: load immediate 10 into s0
    c.li s0, 10
    li t0, 10
    bne s0, t0, c_alu_fail

    # C.ADDI: s0 = s0 + 5 = 15
    c.addi s0, 5
    li t0, 15
    bne s0, t0, c_alu_fail

    # C.LUI: load upper immediate 1 into s1 → s1 = 0x00001000
    c.lui s1, 1
    li t0, 0x00001000
    bne s1, t0, c_alu_fail

    # C.MV: a4 = s0 (= 15)
    c.mv a4, s0
    bne a4, s0, c_alu_fail

    # C.ADD: s0 = s0 + a4 = 15 + 15 = 30
    c.add s0, a4
    li t0, 30
    bne s0, t0, c_alu_fail

    # C.SUB: s0 = s0 - a4 = 30 - 15 = 15
    c.sub s0, a4
    li t0, 15
    bne s0, t0, c_alu_fail

    # C.AND: s0 = s0 & 0x0F = 15 & 0x0F = 0x0F
    c.li a4, 0x0F
    c.and s0, a4
    li t0, 0x0F
    bne s0, t0, c_alu_fail

    # C.OR: s0 = s0 | 0xF0 = 0x0F | 0xF0 = 0xFF
    li a4, 0xF0
    c.or s0, a4
    li t0, 0xFF
    bne s0, t0, c_alu_fail

    # C.XOR: s0 = s0 ^ 0x0F = 0xFF ^ 0x0F = 0xF0
    c.li a4, 0x0F
    c.xor s0, a4
    li t0, 0xF0
    bne s0, t0, c_alu_fail

    # C.ANDI: s0 = s0 & 0x10 = 0xF0 & 0x10 = 0x10
    # note: C.ANDI immediate is 6-bit sign extended, 0x10 = 16
    c.andi s0, 16
    li t0, 16
    bne s0, t0, c_alu_fail

    # C.SLLI: s0 = s0 << 2 = 16 << 2 = 64
    c.slli s0, 2
    li t0, 64
    bne s0, t0, c_alu_fail

    # C.SRLI: s0 = s0 >> 1 = 64 >> 1 = 32 (logical)
    c.srli s0, 1
    li t0, 32
    bne s0, t0, c_alu_fail

    # C.SRAI: load -64, shift right 2 = -16 (arithmetic)
    c.li s0, -16
    c.slli s0, 2                # s0 = -64
    c.srai s0, 2                # s0 = -16
    li t0, -16
    bne s0, t0, c_alu_fail

    # C.ADDI16SP: sp = sp + 16 (immediate is scaled by 16)
    # save sp, add 16, check, then restore
    mv t1, sp
    c.addi16sp sp, 16
    addi t2, t1, 16
    bne sp, t2, c_alu_fail
    mv sp, t1                   # restore sp

    # C.ADDI4SPN: rd = sp + imm (immediate scaled by 4, rd must be s0-a5)
    # we expect s0 = sp + 4
    c.addi4spn s0, sp, 4
    addi t0, sp, 4
    bne s0, t0, c_alu_fail

    lw ra, 0(sp)
    addi sp, sp, 16
    li a0, 1                    # all passed
    ret

c_alu_fail:
    lw ra, 0(sp)
    addi sp, sp, 16
    li a0, 0
    ret