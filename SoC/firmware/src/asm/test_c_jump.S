# test_c_jump.S
# Tests all C-extension jump instructions:
#   C.J, C.JAL, C.JR, C.JALR
# Returns 1 in a0 if all pass, 0 if any fail
#
# Strategy: set flag t1=0 before each jump, target sets t1=1,
# after returning check t1==1.
#
# Note: C.JAL, C.JR, C.JALR have no fail guards after them.
# C.JAL is a 2-byte instruction so ra = pc+2, but the preceding
# sw+li (6 bytes) means a fail guard at pc+2 would be the guard
# itself not the return label. C.JR and C.JALR have the same issue
# due to la expanding to 8 bytes. The flag check at the return
# label catches any failure instead.

.section .text
.global test_c_jump

test_c_jump:
    addi sp, sp, -8
    sw ra, 0(sp)

    # ── C.J ──────────────────────────────────────────
    li t1, 0
    c.j c_j_target
    j c_jump_fail           # only reachable if C.J didn't jump
c_j_return:
    li t2, 1
    bne t1, t2, c_jump_fail

    # ── C.JAL ─────────────────────────────────────────
    sw ra, 4(sp)            # C.JAL overwrites ra, save it
    li t1, 0
    c.jal c_jal_target      # no fail guard — ra = pc+2 lands on c_jal_return
c_jal_return:
    lw ra, 4(sp)
    li t2, 1
    bne t1, t2, c_jump_fail

    # ── C.JR ──────────────────────────────────────────
    li t1, 0
    la t0, c_jr_target      # expands to auipc+addi (8 bytes)
    c.jr t0                 # no fail guard — see note above
c_jr_return:
    li t2, 1
    bne t1, t2, c_jump_fail

    # ── C.JALR ────────────────────────────────────────
    sw ra, 4(sp)            # C.JALR overwrites ra, save it
    li t1, 0
    la t0, c_jalr_target    # expands to auipc+addi (8 bytes)
    c.jalr t0               # no fail guard — see note above
c_jalr_return:
    lw ra, 4(sp)
    li t2, 1
    bne t1, t2, c_jump_fail

    lw ra, 0(sp)
    addi sp, sp, 8
    li a0, 1                # all passed
    ret

c_j_target:
    li t1, 1
    la t0, c_j_return
    c.jr t0                 # C.J has no link, return via register

c_jal_target:
    li t1, 1
    jalr zero, ra, 0        # return via ra saved by C.JAL

c_jr_target:
    li t1, 1
    la t0, c_jr_return
    c.jr t0

c_jalr_target:
    li t1, 1
    jalr zero, ra, 0        # return via ra saved by C.JALR

c_jump_fail:
    lw ra, 0(sp)
    addi sp, sp, 8
    li a0, 0
    ret