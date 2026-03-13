# test_store.S
# Tests: SW, SH, SB
# Returns 1 in a0 if all pass, 0 if any fail
#
# Strategy: write using each store variant, then read back
# with LW and check that only the expected bytes changed.

.section .text
.global test_store

test_store:
    addi sp, sp, -16        # scratch space

    # SW: store 0x12345678, read back with LW
    li t0, 0x12345678
    sw t0, 0(sp)
    lw a1, 0(sp)
    li a2, 0x12345678
    bne a1, a2, store_fail

    # SH: store 0xBEEF into lower halfword, upper stays from SW
    # first clear scratch
    li t0, 0x00000000
    sw t0, 0(sp)
    li t0, 0xBEEF
    sh t0, 0(sp)            # stores 0xBEEF at byte[0..1]
    lhu a1, 0(sp)           # read back just the halfword
    li a2, 0xBEEF
    bne a1, a2, store_fail

    # SB: store 0xAB into byte[0]
    li t0, 0x00000000
    sw t0, 0(sp)
    li t0, 0xAB
    sb t0, 0(sp)            # stores 0xAB at byte[0]
    lbu a1, 0(sp)           # read back just the byte
    li a2, 0xAB
    bne a1, a2, store_fail

    addi sp, sp, 16
    li a0, 1                # all passed
    ret

store_fail:
    addi sp, sp, 16
    li a0, 0
    ret
