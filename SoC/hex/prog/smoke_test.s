    .section .text
    .globl _start
_start:
    ################################################################
    # set up stack pointer to linker .stack _sstack = 0x10800
    # SP = 0x10800  => LUI x2,0x10 (0x10<<12 == 0x10000) + 2048 via two addi
    ################################################################
    lui   x2,0x10           # x2 = 0x10000
    addi  x2,x2,2047        # x2 = 0x10000 + 2047
    addi  x2,x2,1           # x2 = 0x10000 + 2048 = 0x10800  (sp)

    ################################################################
    # data base pointer: RAM base 0x10000 (use LUI)
    # We'll use x3 as data-base (0x10000)
    ################################################################
    lui   x3,0x10           # x3 = 0x10000  (data base)

    ################################################################
    # 1) ADD / SUB (smoke)
    # res_add:   .word results at 0x10000 and 0x10004
    ################################################################
    addi  x5,x0,7           # x5 = 7
    addi  x6,x0,5           # x6 = 5
    add   x7,x5,x6          # x7 = 12
    sw    x7,0(x3)          # [0x10000] = 0x0000000C  (expected)
    sub   x8,x5,x6          # x8 = 2
    sw    x8,4(x3)          # [0x10004] = 0x00000002  (expected)

    ################################################################
    # 2) Logic & Shifts
    # res_logic: words starting at 0x10008
    # order: XOR, OR, AND, SLL, SRL, SRA
    ################################################################
    # construct x9 = 0x0000F0F0
    # imm20 = 0x0000F (15) => 15<<12 = 0x0000F000 ; addi 0xF0 => 0x0000F0F0
    lui   x9,15             # x9 = 0x0000F000
    addi  x9,x9,240         # x9 = 0x0000F0F0

    # construct x10 = 0x00000F0F
    # choose imm20 = 1 -> base = 0x1000 ; addi = 0x0F0F - 0x1000 = -241
    lui   x10,1             # x10 = 0x00001000
    addi  x10,x10,-241      # x10 = 0x00000F0F

    xor   x11,x9,x10        # x11 = 0x0000FFFF
    sw    x11,8(x3)         # [0x10008] = 0x0000FFFF  (expected)

    or    x12,x9,x10        # x12 = 0x0000F0FF
    sw    x12,12(x3)        # [0x1000C] = 0x0000F0FF  (expected)

    and   x13,x9,x10        # x13 = 0x00000000
    sw    x13,16(x3)        # [0x10010] = 0x00000000  (expected)

    # test shifts: sll (register-register), srl (register-register), sra (immediate)
    addi  x14,x0,1          # x14 = 1 (will be rs1 for sll and rs2 for shift-amount)
    sll   x15,x14,x10       # sll by (x10 & 0x1F) -> low 5 bits of 0x0F0F = 15
                            # x15 = 1 << 15 = 0x00008000
    sw    x15,20(x3)        # [0x10014] = 0x00008000  (expected)

    # construct x16 = 0x00008000
    # imm20 = 0x8 => 0x8 << 12 = 0x8000
    lui   x16,8             # x16 = 0x00008000
    addi  x16,x16,0         # no-op addi to avoid pseudoinstructions
    # use register-register SRL with shift amount in x14 (1)
    srl   x17,x16,x14       # logical right shift by 1 -> 0x00004000
    sw    x17,24(x3)        # [0x10018] = 0x00004000  (expected)

    # sra: arithmetic shift right of a negative number (use immediate variant)
    addi  x18,x0,-8         # x18 = 0xFFFFFFF8  (= -8)
    srai  x19,x18,2         # x19 = arith(-8 >> 2) = -2 = 0xFFFFFFFE
    sw    x19,28(x3)        # [0x1001C] = 0xFFFFFFFE  (expected)

    ################################################################
    # 3) Branches (taken / not-taken)
    # results at 0x10020 and 0x10024
    ################################################################
    # BEQ taken test
    addi  x20,x0,5          # x20 = 5
    addi  x21,x0,5          # x21 = 5
    beq   x20,x21,BEQ_TAKEN
    # not-taken path (should not execute)
    addi  x22,x0,0
    sw    x22,32(x3)        # [0x10020] = 0x00000000  (if NOT TAKEN) -- expected NOT to be written
    jal   x0,BEQ_DONE       # jump (no link) to BEQ_DONE

BEQ_TAKEN:
    addi  x22,x0,1
    sw    x22,32(x3)        # [0x10020] = 0x00000001  (expected; BEQ should be taken)

BEQ_DONE:

    # BNE not-taken test
    addi  x23,x0,7
    addi  x24,x0,7
    bne   x23,x24,BNE_TAKEN
    # bne not taken -> store 0
    addi  x25,x0,0
    sw    x25,36(x3)        # [0x10024] = 0x00000000  (expected since not-taken)
    jal   x0,BNE_DONE

BNE_TAKEN:
    addi  x25,x0,1
    sw    x25,36(x3)        # [0x10024] = 0x00000001  (if BNE taken; not expected here)

BNE_DONE:

    ################################################################
    # 4) Loads / Stores (byte / half / word, sign / zero)
    # bytes at addresses 0x10028 .. 0x1002B
    # then loads store results at 0x1002C .. 0x10040
    ################################################################
    addi  x26,x0,128        # 0x80
    sb    x26,40(x3)        # [0x10028] = 0x80    (expected byte)

    addi  x27,x0,1
    sb    x27,41(x3)        # [0x10029] = 0x01    (expected byte)

    addi  x28,x0,-2         # x28 = 0xFFFFFFFE, low byte 0xFE
    sb    x28,42(x3)        # [0x1002A] = 0xFE    (expected byte)

    addi  x29,x0,127
    sb    x29,43(x3)        # [0x1002B] = 0x7F    (expected byte)

    # Loads and write results as words (addresses are absolute offsets from 0x10000)
    lb    x30,40(x3)        # x30 = sign-extend(0x80) = 0xFFFFFF80
    sw    x30,44(x3)        # [0x1002C] = 0xFFFFFF80  (expected)

    lbu   x31,40(x3)        # x31 = zero-extend(0x80) = 0x00000080
    sw    x31,48(x3)        # [0x10030] = 0x00000080  (expected)

    lh    x5,40(x3)         # halfword LE: (0x01 << 8) | 0x80 = 0x0180 -> sign-extended 0x00000180
    sw    x5,52(x3)         # [0x10034] = 0x00000180  (expected)

    lhu   x6,40(x3)         # zero-extend halfword = 0x00000180
    sw    x6,56(x3)         # [0x10038] = 0x00000180  (expected)

    lb    x7,42(x3)         # x7 = sign-extend(0xFE) = 0xFFFFFFFE
    sw    x7,60(x3)         # [0x1003C] = 0xFFFFFFFE  (expected)

    lbu   x8,42(x3)         # x8 = zero-extend(0xFE) = 0x000000FE
    sw    x8,64(x3)         # [0x10040] = 0x000000FE  (expected)

    ################################################################
    # finished tests - use EBREAK to trap in simulators
    ################################################################
    ebreak
    j .                     # infinite loop (shouldn't be reached if ebreak traps)
