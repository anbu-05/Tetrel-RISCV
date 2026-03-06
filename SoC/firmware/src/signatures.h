// signatures.h
// 32 signature registers at top of RAM: 0x00017F80 - 0x00017FFF
//
// Usage:
//   SIG(n) = EXP_SIG(tag)   // pass, tag is any 28-bit value you choose
//   SIG(n) = BAD_SIG(n)     // fail
//   SIG_DONE = DONE_VAL     // always last, signals test complete

#ifndef SIGNATURES_H
#define SIGNATURES_H

#define SIG_BASE 0x00017F80

#define SIG(n)    (*(volatile unsigned int *)(SIG_BASE + (n) * 4))
#define SIG_DONE  SIG(31)

#define DONE_VAL       0xDEADBEEF
#define EXP_SIG(tag)   (0xA0000000 | (tag))
#define BAD_SIG(n)     (0xBAD00000 | (n))

#endif