// imc_verify.c
//
// Full end-to-end test of the ReRAM-IMC block.
//
// IMPORTANT: imc_peripheral sits in S_PROG_HOLD after each TRIG_PROG and
// will NOT accept the next trigger until it receives a CLEAR write.
// So prog_cell must always: trigger → wait for not-busy → clear.
// There is no way to pipeline this — it is serialised by the FSM design.
//
// To keep the cycle count down, zero-weight cells are skipped since the
// ReRAM is already zeroed after TRIG_RESET.
//
// SIGNATURES:
//   SIG(0)  = reached main
//   SIG(1)  = software multiply done
//   SIG(2)  = TRIG_RESET fired
//   SIG(3)  = TRIG_RESET done
//   SIG(4)  = all non-zero weights programmed
//   SIG(5)  = matrix A written to imc_sram
//   SIG(6)  = SRC_ADDR and DST_ADDR written
//   SIG(7)  = TRIG_COMPUTE fired
//   SIG(8)  = TRIG_COMPUTE done (value = raw STATUS: 2=done, 3=error, 0=bad)
//   SIG(9)  = results read back and compared
//   SIG(10) = PASS/FAIL: no ERROR status seen during hardware path
//   SIG(11) = PASS/FAIL: all 256 result values match software reference
//   SIG(31) = DONE

#include "signatures.h"

#define IMC_BASE         0x00030000

#define IMC_PROG_ROW     (*(volatile int *)(IMC_BASE + 0x00))
#define IMC_PROG_COL     (*(volatile int *)(IMC_BASE + 0x04))
#define IMC_PROG_WEIGHT  (*(volatile int *)(IMC_BASE + 0x08))
#define IMC_SRC_ADDR     (*(volatile int *)(IMC_BASE + 0x0C))
#define IMC_DST_ADDR     (*(volatile int *)(IMC_BASE + 0x10))
#define IMC_TRIG_PROG    (*(volatile int *)(IMC_BASE + 0x14))
#define IMC_TRIG_COMPUTE (*(volatile int *)(IMC_BASE + 0x18))
#define IMC_TRIG_RESET   (*(volatile int *)(IMC_BASE + 0x1C))
#define IMC_STATUS       (*(volatile int *)(IMC_BASE + 0x20))
#define IMC_CLEAR        (*(volatile int *)(IMC_BASE + 0x24))

#define IMC_SRAM_BASE    (IMC_BASE + 0x28)
#define IMC_SRAM_WORD(n) (*(volatile int *)(IMC_SRAM_BASE + (n) * 4))

#define SRAM_SRC_WORD    0
#define SRAM_DST_WORD    256

#define IMC_STATUS_BUSY  1
#define IMC_STATUS_DONE  2
#define IMC_STATUS_ERROR 3

#define N 16

// Global arrays — in .bss, not on the stack
int W[N][N];
int A[N][N];
int C_sw[N][N];

// Wait until peripheral leaves BUSY, then write CLEAR to return it to IDLE.
// The peripheral requires this sequence after every trigger before it will
// accept the next one (S_PROG_HOLD / S_RESET_HOLD / S_DONE all gate on CLEAR).
static void imc_finish() {
    while (IMC_STATUS == IMC_STATUS_BUSY);
    IMC_CLEAR = 1;
}

int main() {

    int i, j, r;

    SIG(0) = EXP_SIG(0x00);

    // ── Step 1: Software reference multiply ──────────────────────────────────
    for (i = 0; i < N; i++)
        for (j = 0; j < N; j++)
            W[i][j] = i - j;

    for (r = 0; r < N; r++)
        for (i = 0; i < N; i++)
            A[r][i] = r + i + 1;

    for (r = 0; r < N; r++)
        for (j = 0; j < N; j++) {
            int acc = 0;
            for (i = 0; i < N; i++)
                acc += A[r][i] * W[i][j];
            C_sw[r][j] = acc;
        }

    SIG(1) = EXP_SIG(0x01);

    // ── Step 2: Reset ReRAM ───────────────────────────────────────────────────
    SIG(2) = EXP_SIG(0x02);
    IMC_TRIG_RESET = 1;
    imc_finish();
    SIG(3) = EXP_SIG(0x03);

    // ── Step 3: Program non-zero weights ─────────────────────────────────────
    // Zero cells are skipped — already 0 after reset.
    // Each cell: write ROW, COL, WEIGHT, fire TRIG_PROG, wait, clear.
    // Cannot pipeline — peripheral stays in S_PROG_HOLD until CLEAR is received.
    int hw_ok = 1;

    for (i = 0; i < N; i++) {
        for (j = 0; j < N; j++) {
            if (W[i][j] == 0)
                continue;

            IMC_PROG_ROW    = i;
            IMC_PROG_COL    = j;
            IMC_PROG_WEIGHT = W[i][j];
            IMC_TRIG_PROG   = 1;
            imc_finish();  // wait done + clear before next trigger

            if (IMC_STATUS == IMC_STATUS_ERROR) {
                hw_ok = 0;
                IMC_CLEAR = 1;
            }
        }
    }

    SIG(4) = EXP_SIG(0x04);

    // ── Step 4: Write matrix A into imc_sram ─────────────────────────────────
    for (r = 0; r < N; r++)
        for (i = 0; i < N; i++)
            IMC_SRAM_WORD(SRAM_SRC_WORD + r * N + i) = A[r][i];

    SIG(5) = EXP_SIG(0x05);

    // ── Step 5: Tell peripheral where data lives ──────────────────────────────
    IMC_SRC_ADDR = SRAM_SRC_WORD;
    IMC_DST_ADDR = SRAM_DST_WORD;
    SIG(6) = EXP_SIG(0x06);

    // ── Step 6: Trigger compute ───────────────────────────────────────────────
    SIG(7) = EXP_SIG(0x07);
    IMC_TRIG_COMPUTE = 1;
    while (IMC_STATUS == IMC_STATUS_BUSY);  // wait — do NOT clear yet, read STATUS first

    SIG(8) = EXP_SIG(IMC_STATUS);  // 2=done, 3=error, 0=never left busy (bad)

    if (IMC_STATUS == IMC_STATUS_ERROR)
        hw_ok = 0;
    IMC_CLEAR = 1;

    // ── Step 7: Read back and compare ────────────────────────────────────────
    int match = 1;
    for (r = 0; r < N; r++)
        for (j = 0; j < N; j++) {
            int hw_val = IMC_SRAM_WORD(SRAM_DST_WORD + r * N + j);
            if (hw_val != C_sw[r][j])
                match = 0;
        }
    SIG(9) = EXP_SIG(0x09);

    SIG(10) = hw_ok ? EXP_SIG(0x10) : BAD_SIG(10);
    SIG(11) = match ? EXP_SIG(0x11) : BAD_SIG(11);

    SIG_DONE = DONE_VAL;
    while (1);
    return 0;
}