# test_m.S
# Tests: MUL, MULH, MULHU, MULHSU, DIV, DIVU, REM, REMU
# Returns 1 in a0 if all pass, 0 if any fail

.section .text
.global test_m

test_m:

    # MUL: 6 * 7 = 42 (lower 32 bits)
    li a1, 6
    li a2, 7
    mul a3, a1, a2
    li a4, 42
    bne a3, a4, m_fail

    # MULH: (-1) * (-1) = 1, upper 32 bits of 64-bit signed result = 0
    li a1, -1
    li a2, -1
    mulh a3, a1, a2
    li a4, 0
    bne a3, a4, m_fail

    # MULHU: 0xFFFFFFFF * 0xFFFFFFFF upper 32 bits (unsigned)
    # 0xFFFFFFFF^2 = 0xFFFFFFFE00000001, upper = 0xFFFFFFFE
    li a1, 0xFFFFFFFF
    li a2, 0xFFFFFFFF
    mulhu a3, a1, a2
    li a4, 0xFFFFFFFE
    bne a3, a4, m_fail

    # MULHSU: signed * unsigned
    # (-1) * 1 = -1 as 64-bit = 0xFFFFFFFF_FFFFFFFF, upper = 0xFFFFFFFF
    li a1, -1
    li a2, 1
    mulhsu a3, a1, a2
    li a4, 0xFFFFFFFF
    bne a3, a4, m_fail

    # DIV: 42 / 6 = 7 (signed)
    li a1, 42
    li a2, 6
    div a3, a1, a2
    li a4, 7
    bne a3, a4, m_fail

    # DIVU: 42 / 6 = 7 (unsigned)
    li a1, 42
    li a2, 6
    divu a3, a1, a2
    li a4, 7
    bne a3, a4, m_fail

    # REM: 43 % 6 = 1 (signed)
    li a1, 43
    li a2, 6
    rem a3, a1, a2
    li a4, 1
    bne a3, a4, m_fail

    # REMU: 43 % 6 = 1 (unsigned)
    li a1, 43
    li a2, 6
    remu a3, a1, a2
    li a4, 1
    bne a3, a4, m_fail

    li a0, 1        # all passed
    ret

m_fail:
    li a0, 0
    ret
