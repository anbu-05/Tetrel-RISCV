// imc_sram_test.c
//
// SIG(0) = reached main
// SIG(1) = write word 0 completed
// SIG(2) = PASS/FAIL: word 0 readback correct
// SIG(3) = write word 5 completed
// SIG(4) = PASS/FAIL: word 0 still intact after second write
// SIG(5) = PASS/FAIL: word 5 readback correct
// SIG(31) = DONE

#include "signatures.h"

#define IMC_SRAM_BASE    (0x00030000 + 0x28)
#define IMC_SRAM_WORD(n) (*(volatile int *)(IMC_SRAM_BASE + (n) * 4))

int main() {

    SIG(0) = EXP_SIG(0x00);

    IMC_SRAM_WORD(0) = 0x12345678;
    SIG(1) = EXP_SIG(0x01);

    int val = IMC_SRAM_WORD(0);
    SIG(2) = (val == 0x12345678) ? EXP_SIG(0x02) : BAD_SIG(2);

    IMC_SRAM_WORD(5) = 0xABCDEF01;
    SIG(3) = EXP_SIG(0x03);

    int v0 = IMC_SRAM_WORD(0);
    int v5 = IMC_SRAM_WORD(5);

    // Check separately so we know which one failed
    SIG(4) = (v0 == 0x12345678) ? EXP_SIG(0x04) : BAD_SIG(4);  // word 0 still intact?
    SIG(5) = (v5 == 0xABCDEF01) ? EXP_SIG(0x05) : BAD_SIG(5);  // word 5 correct?

    SIG_DONE = DONE_VAL;
    while (1);
    return 0;
}