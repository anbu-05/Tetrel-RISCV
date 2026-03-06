MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 32K
}

SECTIONS
{
    /* code goes into ROM */
    .text : {
        *(.text*)
    } > ROM

    /* read-only data (constants) goes into ROM */
    .rodata : {
        *(.rodata*)
    } > ROM

    /* variables go into RAM */
    .data : {
        *(.data*)
    } > RAM

    /* zero-initialized variables go into RAM */
    .bss : {
        *(.bss*)
    } > RAM

    /* stack starts at end of RAM */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}