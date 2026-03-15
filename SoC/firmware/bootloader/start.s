.section .text
.global _start
.extern _vtable_base
.global default_handler

/* ─────────────────────────────────────────────
   Memory layout (ROM):

     0x00000000  _start          reset vector, stack init, vtable init, call main
     0x00000100  trap_entry      trap dispatcher (PROGADDR_IRQ = 0x00000100)
     0x00000200  default_handler built-in halt handler

   Vector table (RAM, 0x00010000):
     0x00010000  vector_ecall     → default_handler (overwrite to customise)
     0x00010004  vector_ebreak    → default_handler (overwrite to customise)
     0x00010008  vector_illegal   → default_handler (overwrite to customise)
     0x0001000C  vector_misalign  → default_handler (overwrite to customise)
     0x00010010  vector_panic     → 0x00000000 null  (overwrite to customise)

   vector_panic is checked by default_handler — if nonzero, jumps there.
   If null, default_handler halts in an infinite loop.
───────────────────────────────────────────────── */

_start:
    la sp, _stack_top           /* set up stack pointer */

    /* initialise vector table in RAM */
    la t0, default_handler      /* address of built-in default handler */
    la t1, _vtable_base         /* base of vector table */

    sw t0, 0(t1)                /* vector_ecall    = default_handler */
    sw t0, 4(t1)                /* vector_ebreak   = default_handler */
    sw t0, 8(t1)                /* vector_illegal  = default_handler */
    sw t0, 12(t1)               /* vector_misalign = default_handler */
    sw zero, 16(t1)             /* vector_panic    = 0 (null) */

    call main                   /* jump to main() */

loop:
    j loop                      /* if main() ever returns, hang */


/* ─────────────────────────────────────────────
   trap_entry — lives at 0x00000100 (PROGADDR_IRQ)
   Reads mcause, looks up the right slot in the
   vector table, and jumps to the handler.
───────────────────────────────────────────────── */

.org 0x100
trap_entry:
    csrr t0, mcause             /* read trap cause */

    li t1, 11
    beq t0, t1, trap_ecall      /* mcause 11 = ECALL from M-mode */

    li t1, 8
    beq t0, t1, trap_ecall      /* mcause  8 = ECALL from U-mode */

    li t1, 3
    beq t0, t1, trap_ebreak     /* mcause  3 = EBREAK */

    li t1, 2
    beq t0, t1, trap_illegal    /* mcause  2 = illegal instruction */

    li t1, 0
    beq t0, t1, trap_misalign   /* mcause  0 = instruction misalign */

    j default_handler           /* anything else → default */

trap_ecall:
    la t0, _vtable_base
    lw t0, 0(t0)                /* load vector_ecall */
    jalr zero, t0, 0

trap_ebreak:
    la t0, _vtable_base
    lw t0, 4(t0)                /* load vector_ebreak */
    jalr zero, t0, 0

trap_illegal:
    la t0, _vtable_base
    lw t0, 8(t0)                /* load vector_illegal */
    jalr zero, t0, 0

trap_misalign:
    la t0, _vtable_base
    lw t0, 12(t0)               /* load vector_misalign */
    jalr zero, t0, 0


/* ─────────────────────────────────────────────
   default_handler — lives at 0x00000200
   Called when a trap fires and no specific user
   handler has been installed for that trap type.

   Checks vector_panic (slot 4 in the table):
     - if nonzero → jumps to user's panic handler
     - if zero    → halts (infinite loop)
───────────────────────────────────────────────── */

.org 0x200
default_handler:
    la t0, _vtable_base
    lw t0, 16(t0)               /* load vector_panic */
    beq t0, zero, halt          /* if null, halt */
    jalr zero, t0, 0            /* otherwise jump to user panic handler */

halt:
    j halt
