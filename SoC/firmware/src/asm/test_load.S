# test_load.S
# Tests: LW, LH, LB, LHU, LBU
# Returns 1 in a0 if all pass, 0 if any fail
#
# Strategy: store a known word into a stack scratch area,
# then load it back using each load variant and check the result.
# The word stored is 0xAABBCCDD
#   byte[0] (lowest addr) = 0xDD  (little-endian)
#   byte[1]               = 0xCC
#   halfword[0]           = 0xCCDD

.section .text
.global test_load

test_load:
    addi sp, sp, -16        # make room on stack

    # write known word to scratch area
    li t0, 0xAABBCCDD
    sw t0, 0(sp)

    # LW: load full word = 0xAABBCCDD
    lw a1, 0(sp)
    li a2, 0xAABBCCDD
    bne a1, a2, load_fail

    # LB: load signed byte[0] = 0xDD = -35 (sign extended)
    lb a1, 0(sp)
    li a2, -35
    bne a1, a2, load_fail

    # LBU: load unsigned byte[0] = 0xDD = 221
    lbu a1, 0(sp)
    li a2, 221
    bne a1, a2, load_fail

    # LH: load signed halfword[0] = 0xCCDD = -13091 (sign extended)
    lh a1, 0(sp)
    li a2, -13091
    bne a1, a2, load_fail

    # LHU: load unsigned halfword[0] = 0xCCDD = 52445
    lhu a1, 0(sp)
    li a2, 52445
    bne a1, a2, load_fail

    addi sp, sp, 16
    li a0, 1                # all passed
    ret

load_fail:
    addi sp, sp, 16
    li a0, 0
    ret
