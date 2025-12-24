    .section .text
    .globl _start
_start:
    # base = 0x18000
    lui   x5, 0x18            # x5 = UART base (0x18000)

    # -------------------------
    # CLKDIV = 1
    # -------------------------
    addi  x6, x0, 1
    sw    x6, 4(x5)

# -------------------------
# send 'H'
# -------------------------
wait_H:
    lw    x6, 0(x5)           # read FLAGS
    andi  x6, x6, 1           # isolate TX_READY
    beqz  x6, wait_H          # wait while not ready

    addi  x7, x0, 72          # 'H'
    sb    x7, 8(x5)

# -------------------------
# send 'i'
# -------------------------
wait_i:
    lw    x6, 0(x5)
    andi  x6, x6, 1
    beqz  x6, wait_i

    addi  x7, x0, 105         # 'i'
    sb    x7, 8(x5)

# -------------------------
# send '\n'
# -------------------------
wait_nl:
    lw    x6, 0(x5)
    andi  x6, x6, 1
    beqz  x6, wait_nl

    addi  x7, x0, 10          # '\n'
    sb    x7, 8(x5)

# -------------------------
# halt forever
# -------------------------
hang:
    jal   x0, hang

    .size _start, .-_start
