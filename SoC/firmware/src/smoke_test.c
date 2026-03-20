// smoke_test.c
// Slot assignments (only this file needs to know):
//   SIG(0)  = CPU ADD result
//   SIG(1)  = CPU MUL result
//   SIG(2)  = UART TX result
//   SIG(3)  = GPIO readback result
//   SIG(31) = DONE

#include "signatures.h"

#define UART_STATUS (*(volatile unsigned int *)0xFFFF1000)
#define UART_DIV    (*(volatile unsigned int *)0xFFFF1004)
#define UART_DAT    (*(volatile unsigned int *)0xFFFF1008)

#define GPIO_DATA   (*(volatile unsigned int *)0xFFFF2000)
#define GPIO_DIR    (*(volatile unsigned int *)0xFFFF2004)

int cpu_add(int a, int b) { return a + b; }
int cpu_mul(int a, int b) { return a * b; }

int main() {

    // SIG(0): CPU ADD
    if (cpu_add(10, 20) == 30)
        SIG(0) = EXP_SIG(0xADD);
    else
        SIG(0) = BAD_SIG(0);

    // SIG(1): CPU MUL
    if (cpu_mul(6, 7) == 42)
        SIG(1) = EXP_SIG(0xA1);
    else
        SIG(1) = BAD_SIG(1);

    // SIG(2): UART TX
    UART_DIV = 1;
    while (!(UART_STATUS & 1));
    UART_DAT = 0x41;
    while (!(UART_STATUS & 1));
    SIG(2) = EXP_SIG(0xA2);

    // SIG(3): GPIO readback
    GPIO_DIR  = 0xFFFFFFFF;
    GPIO_DATA = 0xAAAAAAAA;
    if (GPIO_DATA == 0xAAAAAAAA)
        SIG(3) = EXP_SIG(0xA3);
    else
        SIG(3) = BAD_SIG(3);

    SIG_DONE = DONE_VAL;

    while (1);
    return 0;
}