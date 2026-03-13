# test_upper.S
# Tests: LUI, AUIPC
# Returns 1 in a0 if all pass, 0 if any fail

.section .text
.global test_upper

test_upper:

    # LUI: load upper immediate 0xABCDE into upper 20 bits
    # result should be 0xABCDE000
    lui a1, 0xABCDE
    li  a2, 0xABCDE000
    bne a1, a2, upper_fail

    # AUIPC: add upper immediate to PC
    # We can't know the exact PC at runtime, but we can check
    # that the result is close to where we are (within the ROM range).
    # ROM is 0x00000000 - 0x0000FFFF, so result must be in that range.
    auipc a1, 0            # a1 = PC + 0 = current PC
    li    a2, 0x00000000
    blt   a1, a2, upper_fail   # must be >= 0
    li    a2, 0x0000FFFF
    bgt   a1, a2, upper_fail   # must be <= end of ROM

    li a0, 1               # all passed
    ret

upper_fail:
    li a0, 0
    ret
