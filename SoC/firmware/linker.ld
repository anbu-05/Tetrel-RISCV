MEMORY
{
    RAM (rx)  : ORIGIN = 0x00000000, LENGTH = 128K
}

SECTIONS
{
    .text   : { *(.text*)   } > RAM
    .rodata : { *(.rodata*) } > RAM
    .data   : { *(.data*)   } > RAM
    .bss    : { *(.bss*)    } > RAM

    /* Top 128 bytes of RAM reserved for signature registers.
       Stack must not grow into 0x0001FF80 - 0x0001FFFF. */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM) - 128;
}