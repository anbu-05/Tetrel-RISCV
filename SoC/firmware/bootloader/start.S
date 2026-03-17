.section .text
.global _start

/* ─────────────────────────────────────────────
   _start — reset vector
   Initialises the stack pointer and calls main().
   If main() ever returns, hangs in an infinite loop.

   IRQ/trap support is not implemented yet.
   When needed, this file will be expanded with:
     - IRQ vector table initialisation
     - trap_entry dispatcher (at PROGADDR_IRQ)
     - default_handler
   See README for details.
───────────────────────────────────────────────── */

_start:
    la sp, _stack_top    /* load stack pointer from linker.ld */
    call main            /* jump to main() */

loop:
    j loop               /* if main() ever returns, hang */