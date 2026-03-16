// unit_test_instr.c
// Calls each assembly test function and writes pass/fail to signature slots.
//
// Slot assignments:
//   SIG(0)  = ALU Register      (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU)
//   SIG(1)  = ALU Immediate     (ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU)
//   SIG(2)  = Load              (LW, LH, LB, LHU, LBU)
//   SIG(3)  = Store             (SW, SH, SB)
//   SIG(4)  = Branch            (BEQ, BNE, BLT, BGE, BLTU, BGEU)
//   SIG(5)  = Jump              (JAL, JALR)
//   SIG(6)  = Upper Imm         (LUI, AUIPC)
//   SIG(7)  = M-extension       (MUL, MULH, MULHU, MULHSU, DIV, DIVU, REM, REMU)
//   SIG(8)  = C-extension ALU   (C.NOP, C.ADDI, C.ADDI16SP, C.ADDI4SPN, C.LI, C.LUI,
//                                C.MV, C.ADD, C.AND, C.OR, C.XOR, C.SUB,
//                                C.SLLI, C.SRLI, C.SRAI, C.ANDI)
//   SIG(9)  = C-extension Load/Store (C.LW, C.SW, C.LWSP, C.SWSP)
//   SIG(10) = C-extension Branch     (C.BEQZ, C.BNEZ)
//   SIG(11) = C-extension Jump       (C.J, C.JAL, C.JR, C.JALR)
//   SIG(31) = DONE
//
// Not tested: ECALL, EBREAK, C.EBREAK, FENCE
// See README for explanation.

#include "signatures.h"

int test_alu_reg(void);
int test_alu_imm(void);
int test_load(void);
int test_store(void);
int test_branch(void);
int test_jump(void);
int test_upper(void);
int test_m(void);
int test_c_alu(void);
int test_c_loadstore(void);
int test_c_branch(void);
int test_c_jump(void);

int main() {

    SIG(0)  = test_alu_reg()      ? EXP_SIG(0x0)  : BAD_SIG(0);
    SIG(1)  = test_alu_imm()      ? EXP_SIG(0x1)  : BAD_SIG(1);
    SIG(2)  = test_load()         ? EXP_SIG(0x2)  : BAD_SIG(2);
    SIG(3)  = test_store()        ? EXP_SIG(0x3)  : BAD_SIG(3);
    SIG(4)  = test_branch()       ? EXP_SIG(0x4)  : BAD_SIG(4);
    SIG(5)  = test_jump()         ? EXP_SIG(0x5)  : BAD_SIG(5);
    SIG(6)  = test_upper()        ? EXP_SIG(0x6)  : BAD_SIG(6);
    SIG(7)  = test_m()            ? EXP_SIG(0x7)  : BAD_SIG(7);
    SIG(8)  = test_c_alu()        ? EXP_SIG(0x8)  : BAD_SIG(8);
    SIG(9)  = test_c_loadstore()  ? EXP_SIG(0x9)  : BAD_SIG(9);
    SIG(10) = test_c_branch()     ? EXP_SIG(0xA)  : BAD_SIG(10);
    SIG(11) = test_c_jump()       ? EXP_SIG(0xB)  : BAD_SIG(11);

    SIG_DONE = DONE_VAL;

    while (1);
    return 0;
}