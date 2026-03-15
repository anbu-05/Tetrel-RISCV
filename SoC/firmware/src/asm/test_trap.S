# test_trap.S
# Tests the trap system and system instructions:
#   ECALL, EBREAK, C.EBREAK
#
# Strategy:
#   Before each trap instruction, install a custom handler into the
#   relevant vector table slot. The handler sets a flag in RAM, does
#   mepc+4 to skip past the trapping instruction, then returns via mret.
#   After the trap, the test checks the flag was set.
#
# Vector table base: 0x00010000
#   +0  vector_ecall
#   +4  vector_ebreak
#   +20 vector_panic (used for C.EBREAK since it fires as EBREAK)
#
# Flag location: uses a scratch word on the stack.
# Returns 1 in a0 if all pass, 0 if any fail.

.section .text
.global test_trap
.extern default_handler

# address of our scratch flag — passed to handlers via a global label
.global _trap_flag

test_trap:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw zero, 4(sp)              # scratch flag at 4(sp), init to 0

    # store flag address in a global so handlers can find it
    la t0, _trap_flag_addr
    addi t1, sp, 4
    sw t1, 0(t0)                # _trap_flag_addr = &flag

    # ── ECALL ──────────────────────────────────────────
    # install ecall_test_handler into vector_ecall (0x00010000)
    la t0, ecall_test_handler
    li t1, 0x00010000
    sw t0, 0(t1)

    sw zero, 4(sp)              # clear flag
    ecall                       # fires trap, handler sets flag, mret returns here

    lw t0, 4(sp)
    li t1, 1
    bne t0, t1, trap_fail       # flag must be 1

    # restore vector_ecall to default_handler
    la t0, default_handler
    li t1, 0x00010000
    sw t0, 0(t1)

    # ── EBREAK ─────────────────────────────────────────
    # install ebreak_test_handler into vector_ebreak (0x00010004)
    la t0, ebreak_test_handler
    li t1, 0x00010000
    sw t0, 4(t1)

    sw zero, 4(sp)              # clear flag
    ebreak                      # fires trap, handler sets flag, mret returns here

    lw t0, 4(sp)
    li t1, 1
    bne t0, t1, trap_fail

    # restore vector_ebreak to default_handler
    la t0, default_handler
    li t1, 0x00010000
    sw t0, 4(t1)

    # ── C.EBREAK ───────────────────────────────────────
    # C.EBREAK fires the same EBREAK trap (mcause=3)
    # reinstall ebreak_test_handler
    la t0, ebreak_test_handler
    li t1, 0x00010000
    sw t0, 4(t1)

    sw zero, 4(sp)              # clear flag
    c.ebreak                    # compressed EBREAK, same trap

    lw t0, 4(sp)
    li t1, 1
    bne t0, t1, trap_fail

    # restore
    la t0, default_handler
    li t1, 0x00010000
    sw t0, 4(t1)

    lw ra, 0(sp)
    addi sp, sp, 8
    li a0, 1                    # all passed
    ret

trap_fail:
    # restore vector table entries before returning
    la t0, default_handler
    li t1, 0x00010000
    sw t0, 0(t1)
    sw t0, 4(t1)

    lw ra, 0(sp)
    addi sp, sp, 8
    li a0, 0
    ret


# ── Test handlers ───────────────────────────────────
# These are installed temporarily during the test.
# Each one: sets the flag, increments mepc by 4, returns via mret.

ecall_test_handler:
    la t0, _trap_flag_addr
    lw t0, 0(t0)                # t0 = address of flag
    li t1, 1
    sw t1, 0(t0)                # flag = 1
    csrr t0, mepc
    addi t0, t0, 4              # skip past ECALL
    csrw mepc, t0
    mret

ebreak_test_handler:
    la t0, _trap_flag_addr
    lw t0, 0(t0)                # t0 = address of flag
    li t1, 1
    sw t1, 0(t0)                # flag = 1
    csrr t0, mepc
    addi t0, t0, 4              # skip past EBREAK / C.EBREAK
    csrw mepc, t0
    mret


# ── Storage ─────────────────────────────────────────
# one word to hold the address of the current flag location
_trap_flag_addr:
    .word 0
