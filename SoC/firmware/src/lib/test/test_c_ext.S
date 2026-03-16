# test_c_ext.S
# C-extension spot-check
# Explicitly encodes a handful of compressed instructions to verify
# the CPU decodes and executes them correctly.
#
# Compressed instructions tested:
#   C.ADD   (c.add)
#   C.MV    (c.mv)
#   C.LI    (c.li)
#   C.LW    (c.lw)
#   C.SW    (c.sw)
#   C.ADDI  (c.addi)
#   C.J     (c.j)
#   C.BEQZ  (c.beqz)
#
# Returns 1 in a0 if all pass, 0 if any fail
#
# Note: c.sw and c.lw require BOTH the base and data registers to be
# in the range s0-a5 (x8-x15). sp is not valid as a base for these forms.
# We use s0 as the base register pointing into our stack scratch area.

.section .text
.global test_c_ext

test_c_ext:
    addi sp, sp, -16
    sw ra, 0(sp)

    # C.LI: load immediate 10 into a1
    c.li a1, 10
    li a2, 10
    bne a1, a2, c_ext_fail

    # C.MV: copy a1 into a3
    c.mv a3, a1
    bne a3, a1, c_ext_fail

    # C.ADD: a1 = a1 + a3 = 10 + 10 = 20
    c.add a1, a3
    li a2, 20
    bne a1, a2, c_ext_fail

    # C.ADDI: a1 = a1 + 5 = 25
    c.addi a1, 5
    li a2, 25
    bne a1, a2, c_ext_fail

    # C.SW / C.LW: use s0 as base (points to scratch slot at 8(sp))
    addi s0, sp, 8
    c.sw a1, 0(s0)
    c.lw s1, 0(s0)
    bne s1, a1, c_ext_fail

    # C.BEQZ: a2 holds 25, set s0 = 25 - 25 = 0, beqz should branch
    li s0, 25
    sub s0, s0, a2          # s0 = 0
    c.beqz s0, c_beqz_taken
    j c_ext_fail
c_beqz_taken:

    # C.J: unconditional jump
    c.j c_j_taken
    j c_ext_fail
c_j_taken:

    lw ra, 0(sp)
    addi sp, sp, 16
    li a0, 1                # all passed
    ret

c_ext_fail:
    lw ra, 0(sp)
    addi sp, sp, 16
    li a0, 0
    ret