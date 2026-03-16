MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 32K
}

SECTIONS
{
    .text   : { *(.text*)   } > ROM
    .rodata : { *(.rodata*) } > ROM
    .data   : { *(.data*)   } > RAM
    .bss    : { *(.bss*)    } > RAM

    /* Top 128 bytes of RAM reserved for signature registers.
       Stack must not grow into 0x00017F80 - 0x00017FFF. */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM) - 128;
}