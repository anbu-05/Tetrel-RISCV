# test_branch.S
# Tests: BEQ, BNE, BLT, BGE, BLTU, BGEU
# Returns 1 in a0 if all pass, 0 if any fail
#
# Strategy for each branch:
#   - set result register to 0 (fail)
#   - execute the branch; if taken correctly, jump to a block that sets it to 1
#   - also test the NOT-taken case to confirm it doesn't branch when it shouldn't

.section .text
.global test_branch

test_branch:
    li t0, 0        # running pass/fail, 0 = pass so far

    # BEQ: 5 == 5 should branch
    li a1, 5
    li a2, 5
    li t1, 0
    beq a1, a2, beq_taken
    j branch_fail
beq_taken:
    # BEQ: 5 == 6 should NOT branch
    li a2, 6
    beq a1, a2, branch_fail

    # BNE: 5 != 6 should branch
    li a1, 5
    li a2, 6
    bne a1, a2, bne_taken
    j branch_fail
bne_taken:
    # BNE: 5 != 5 should NOT branch
    li a2, 5
    bne a1, a2, branch_fail

    # BLT: 3 < 10 should branch (signed)
    li a1, 3
    li a2, 10
    blt a1, a2, blt_taken
    j branch_fail
blt_taken:
    # BLT: 10 < 3 should NOT branch
    blt a2, a1, branch_fail

    # BGE: 10 >= 3 should branch (signed)
    li a1, 10
    li a2, 3
    bge a1, a2, bge_taken
    j branch_fail
bge_taken:
    # BGE: 3 >= 10 should NOT branch
    bge a2, a1, branch_fail

    # BLTU: 3 < 10 should branch (unsigned)
    li a1, 3
    li a2, 10
    bltu a1, a2, bltu_taken
    j branch_fail
bltu_taken:
    # BLTU: 10 < 3 should NOT branch
    bltu a2, a1, branch_fail

    # BGEU: 10 >= 3 should branch (unsigned)
    li a1, 10
    li a2, 3
    bgeu a1, a2, bgeu_taken
    j branch_fail
bgeu_taken:
    # BGEU: 3 >= 10 should NOT branch
    bgeu a2, a1, branch_fail

    li a0, 1        # all passed
    ret

branch_fail:
    li a0, 0
    ret
