// =============================================================================
// imc_dma.sv
//
// WHAT THIS DOES:
//   Moves data between imc_sram and the ReRAM array's input/output vectors.
//   The peripheral FSM triggers it; the DMA executes the burst and pulses done.
//
// TWO OPERATIONS:
//
//   LOAD (trig_in HIGH for one cycle):
//     Reads 16 consecutive words from imc_sram starting at word address:
//         src_addr + (row * 16)
//     Stores them into input_vec[0..15].
//     Pulses dma_done for one cycle when all 16 words are loaded.
//     The peripheral then sets reram_mode=COMPUTE.
//
//   SAVE (trig_out HIGH for one cycle):
//     Reads output_vec[0..15] from the ReRAM array (already stable —
//     peripheral only fires trig_out after reram_done).
//     Writes 16 consecutive words to imc_sram starting at word address:
//         dst_addr + (row * 16)
//     Pulses dma_done for one cycle when all 16 words are written.
//
// ADDRESSING:
//   src_addr and dst_addr from the peripheral are 15-bit word base addresses.
//   Each row is 16 words. Word address of element i in row r:
//       base + r*16 + i
//
// SRAM INTERFACE — COMBINATIONAL OUTPUTS:
//   sram_addr, sram_wdata, sram_we are all combinational (assign statements).
//   This is critical: imc_sram has a 1-cycle registered read. If sram_addr
//   were registered inside this module it would add a second pipeline stage,
//   making addresses arrive 1 cycle late for both reads and writes.
//
//   With combinational sram_addr:
//     LOAD: S_LOAD_ADDR presents addr combinationally → SRAM registers rdata
//           on that posedge → S_LOAD_DATA reads correct rdata next cycle. ✓
//     SAVE: S_SAVE presents addr+wdata+we combinationally → SRAM writes on
//           that same posedge → correct word written at correct address. ✓
//
// FSM STATES:
//   S_IDLE      — wait for trig_in or trig_out
//   S_LOAD_ADDR — present SRAM read address (combinationally); advance next cycle
//   S_LOAD_DATA — latch sram_rdata into input_vec; go back to S_LOAD_ADDR or done
//   S_SAVE      — present SRAM write (combinationally); advance word_cnt each cycle
//   S_DONE      — pulse dma_done for one cycle; return to S_IDLE
//
// =============================================================================

module imc_dma (
    input  logic clk,
    input  logic rst,           // active-HIGH

    // ── Handshake with imc_peripheral ────────────────────────────────────────
    input  logic        trig_in,      // pulse: load row from SRAM → input_vec
    input  logic        trig_out,     // pulse: save output_vec → SRAM
    input  logic [14:0] src_addr,     // word base address of matrix A in SRAM
    input  logic [14:0] dst_addr,     // word base address of results in SRAM
    input  logic [3:0]  row,          // which row (0-15) to load/save
    output logic        dma_done,     // pulses HIGH one cycle when finished

    // ── ReRAM input vector (DMA fills this before each COMPUTE) ──────────────
    output logic signed [31:0] input_vec  [16],

    // ── ReRAM output vector (DMA reads this after each COMPUTE) ──────────────
    input  logic signed [31:0] output_vec [16],

    // ── imc_sram interface ────────────────────────────────────────────────────
    output logic [14:0]        sram_addr,   // combinational — see note above
    output logic signed [31:0] sram_wdata,  // combinational
    output logic               sram_we,     // combinational
    input  logic signed [31:0] sram_rdata
);

    // ── FSM states ────────────────────────────────────────────────────────────
    typedef enum logic [2:0] {
        S_IDLE      = 3'd0,
        S_LOAD_ADDR = 3'd1,
        S_LOAD_DATA = 3'd2,
        S_SAVE      = 3'd3,
        S_DONE      = 3'd4
    } state_t;

    state_t state;

    // ── Word counter: steps through elements 0-15 of one row ─────────────────
    logic [3:0] word_cnt;

    // ── Latched addresses (captured when trigger fires) ───────────────────────
    logic [14:0] lat_src;
    logic [14:0] lat_dst;
    logic [3:0]  lat_row;
    logic        doing_save;

    // ── Current word address (combinational) ─────────────────────────────────
    // base  +  row*16  +  word_cnt
    // lat_row is 4 bits → {10'b0, lat_row, 4'b0} = 15 bits ✓
    // word_cnt is 4 bits → {11'b0, word_cnt}      = 15 bits ✓
    logic [14:0] cur_word_addr;
    assign cur_word_addr = (doing_save ? lat_dst : lat_src)
                         + {10'b0, lat_row, 4'b0}
                         + {11'b0, word_cnt};

    // ── SRAM outputs — purely combinational ──────────────────────────────────
    // Driven directly from FSM state and cur_word_addr.
    // No register stage here — the SRAM's own always_ff provides the 1-cycle
    // read latency that S_LOAD_ADDR → S_LOAD_DATA accounts for.
    always_comb begin
        sram_addr  = cur_word_addr;
        sram_wdata = output_vec[word_cnt];
        sram_we    = (state == S_SAVE);
    end

    // ── Sequential FSM ────────────────────────────────────────────────────────
    always_ff @(posedge clk) begin
        if (rst) begin
            state      <= S_IDLE;
            word_cnt   <= '0;
            dma_done   <= 1'b0;
            doing_save <= 1'b0;
            lat_src    <= '0;
            lat_dst    <= '0;
            lat_row    <= '0;
            foreach (input_vec[i]) input_vec[i] <= '0;
        end else begin

            dma_done <= 1'b0;  // default — only HIGH in S_DONE

            case (state)

                // ── Wait for trigger ──────────────────────────────────────────
                S_IDLE: begin
                    word_cnt <= '0;
                    if (trig_in) begin
                        lat_src    <= src_addr;
                        lat_dst    <= dst_addr;
                        lat_row    <= row;
                        doing_save <= 1'b0;
                        state      <= S_LOAD_ADDR;
                    end else if (trig_out) begin
                        lat_src    <= src_addr;
                        lat_dst    <= dst_addr;
                        lat_row    <= row;
                        doing_save <= 1'b1;
                        state      <= S_SAVE;
                    end
                end

                // ── LOAD step 1: address phase ────────────────────────────────
                // sram_addr is combinationally = cur_word_addr this cycle.
                // imc_sram registers rdata = mem[cur_word_addr] on this posedge.
                // We just advance state; rdata will be valid next cycle.
                S_LOAD_ADDR: begin
                    state <= S_LOAD_DATA;
                end

                // ── LOAD step 2: data capture phase ──────────────────────────
                // sram_rdata is now mem[addr we presented last cycle]. Latch it.
                // Note: sram_addr is still combinationally = cur_word_addr which
                // uses the current (not yet incremented) word_cnt — same address
                // as last cycle, so SRAM rdata is still valid here. ✓
                S_LOAD_DATA: begin
                    input_vec[word_cnt] <= sram_rdata;
                    if (word_cnt == 4'd15) begin
                        state <= S_DONE;
                    end else begin
                        word_cnt <= word_cnt + 1;
                        state    <= S_LOAD_ADDR;
                    end
                end

                // ── SAVE: write output_vec to SRAM ────────────────────────────
                // sram_addr = cur_word_addr, sram_wdata = output_vec[word_cnt],
                // sram_we = 1 — all combinational, so SRAM sees the correct
                // address and data THIS cycle and commits the write on THIS posedge.
                S_SAVE: begin
                    if (word_cnt == 4'd15) begin
                        state <= S_DONE;
                    end else begin
                        word_cnt <= word_cnt + 1;
                    end
                end

                // ── DONE: pulse dma_done one cycle, return to idle ────────────
                S_DONE: begin
                    dma_done <= 1'b1;
                    word_cnt <= '0;
                    state    <= S_IDLE;
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule
