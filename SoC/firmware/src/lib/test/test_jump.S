# test_jump.S
# Tests: JAL, JALR
# Returns 1 in a0 if all pass, 0 if any fail
#
# Strategy:
#   JAL  — jump to a label, confirm we got there by setting a flag,
#           then return via ra. If ra was wrong we won't come back here.
#   JALR — same, but jump via address in register.
#
# We don't verify the exact value of ra inside the target because
# comparing ra against a label requires la which is a pseudo-instruction
# that may expand differently depending on the linker layout.
# Instead, correct ra is proven implicitly: if we return to the right
# place after the jump, ra was correct.

.section .text
.global test_jump

test_jump:
    addi sp, sp, -4
    sw ra, 0(sp)

    li t1, 0                # flag: 0 = jal target not reached

    # JAL: jump to jal_target, set flag there, return via ra
    jal ra, jal_target
    # - if we're here, JAL returned correctly
    li t2, 1
    bne t1, t2, jump_fail   # flag must have been set in jal_target

    li t1, 0                # reset flag for JALR test

    # JALR: load address of jalr_target, jump via JALR
    la t0, jalr_target
    jalr ra, t0, 0
    # - if we're here, JALR returned correctly
    li t2, 1
    bne t1, t2, jump_fail   # flag must have been set in jalr_target

    lw ra, 0(sp)
    addi sp, sp, 4
    li a0, 1                # all passed
    ret

jal_target:
    li t1, 1                # set flag to prove we got here
    jalr zero, ra, 0        # return via ra

jalr_target:
    li t1, 1                # set flag to prove we got here
    jalr zero, ra, 0        # return via ra

jump_fail:
    lw ra, 0(sp)
    addi sp, sp, 4
    li a0, 0
    ret