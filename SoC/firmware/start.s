.section .text
.global _start

_start:
    la sp, _stack_top    /* load stack pointer from linker.ld */
    call main            /* jump to main() */

loop:
    j loop               /* if main() ever returns, hang forever */