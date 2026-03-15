# test_c_branch.S
# Tests all C-extension branch instructions:
#   C.BEQZ, C.BNEZ
# Each is tested both taken and not-taken.
# Returns 1 in a0 if all pass, 0 if any fail

.section .text
.global test_c_branch

test_c_branch:

    # C.BEQZ: s0 == 0 should branch
    c.li s0, 0
    c.beqz s0, c_beqz_taken
    j c_branch_fail
c_beqz_taken:
    # C.BEQZ: s0 != 0 should NOT branch
    c.li s0, 1
    c.beqz s0, c_branch_fail

    # C.BNEZ: s0 != 0 should branch
    c.li s0, 1
    c.bnez s0, c_bnez_taken
    j c_branch_fail
c_bnez_taken:
    # C.BNEZ: s0 == 0 should NOT branch
    c.li s0, 0
    c.bnez s0, c_branch_fail

    li a0, 1                    # all passed
    ret

c_branch_fail:
    li a0, 0
    ret
