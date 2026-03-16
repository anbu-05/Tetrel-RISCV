# test_c_loadstore.S
# Tests all C-extension load/store instructions:
#   C.LW, C.SW, C.LWSP, C.SWSP
# Returns 1 in a0 if all pass, 0 if any fail
#
# Note: C.LW and C.SW require both base and data registers
# in the range s0-a5 (x8-x15). sp is not valid as a base
# for these forms. We use s0 as the base register.
# C.LWSP and C.SWSP use sp directly as the base.

.section .text
.global test_c_loadstore

test_c_loadstore:
    addi sp, sp, -16
    sw ra, 0(sp)

    # C.SW / C.LW: use s0 as base pointing to scratch at 8(sp)
    li s1, 0xDEADBEEF
    addi s0, sp, 8
    c.sw s1, 0(s0)              # store 0xDEADBEEF to scratch
    c.lw a4, 0(s0)              # load it back
    bne a4, s1, c_ls_fail

    # C.SWSP / C.LWSP: use sp directly as base
    li t0, 0xCAFEBABE
    c.swsp t0, 8(sp)            # store to 8(sp)
    c.lwsp t1, 8(sp)            # load back
    bne t1, t0, c_ls_fail

    lw ra, 0(sp)
    addi sp, sp, 16
    li a0, 1                    # all passed
    ret

c_ls_fail:
    lw ra, 0(sp)
    addi sp, sp, 16
    li a0, 0
    ret