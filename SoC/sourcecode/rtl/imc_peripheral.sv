// =============================================================================
// imc_peripheral.sv
//
// WHAT THIS MODULE DOES:
//   Sits between the RISC-V core (via AXI4-Lite) and the ReRAM array.
//   The core configures it by writing registers, then triggers an operation.
//   The peripheral tells the ReRAM what to do and tells the DMA when to move
//   data. It does NOT touch SRAM directly — that is the DMA's job.
//
// REGISTER MAP (core writes to BASE_ADDR + offset):
//   0x00  PROG_ROW     — which row to write a weight into (0-15)
//   0x04  PROG_COL     — which col to write a weight into (0-15)
//   0x08  PROG_WEIGHT  — the weight value
//   0x0C  SRC_ADDR     — where matrix A starts in SRAM (given to DMA)
//   0x10  DST_ADDR     — where to write result in SRAM  (given to DMA)
//   0x14  TRIG_PROG    — write anything → programs one ReRAM cell
//   0x18  TRIG_COMPUTE — write anything → starts full matrix multiply
//   0x1C  TRIG_RESET   — write anything → resets all ReRAM weights
//   0x20  STATUS       — read: 0=idle  1=busy  2=done  3=error
//   0x24  CLEAR        — write anything → clears STATUS back to idle
//
// HOW COMPUTE WORKS (peripheral perspective):
//   For each row r of matrix A (0 to 15):
//     1. Tell DMA: read row r from SRAM → ReRAM input  (dma_trig_in)
//     2. Wait for DMA to finish              (dma_done)
//     3. Tell ReRAM: compute                 (reram_mode = COMPUTE)
//     4. Wait for ReRAM to finish            (reram_done)
//     5. Tell DMA: write output row to SRAM  (dma_trig_out)
//     6. Wait for DMA to finish              (dma_done)
//   After all 16 rows → STATUS = done
//
// AXI4-LITE SLAVE:
//   Standard 5-channel AXI4-Lite slave interface.
//   Writes: AW + W channels → register file
//   Reads:  AR + R channels → STATUS register
// =============================================================================

module imc_peripheral (
    input  logic clk,
    input  logic rst,

    // ── AXI4-Lite Slave (core-facing) ────────────────────────────────────────

    // Write address channel
    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // Write data channel
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,   // intentionally ignored — we always write full 32-bit words
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // Write response channel
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    // Read address channel
    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // Read data channel
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // ── ReRAM array interface ─────────────────────────────────────────────────
    output logic [1:0]         reram_mode,
    output logic [3:0]         reram_prog_row,
    output logic [3:0]         reram_prog_col,
    output logic signed [31:0] reram_prog_weight,
    input  logic               reram_done,

    // ── DMA interface ─────────────────────────────────────────────────────────
    // peripheral tells DMA what to do, DMA signals when done
    output logic        dma_trig_in,      // tell DMA: load input row → ReRAM
    output logic        dma_trig_out,     // tell DMA: save output row → SRAM
    output logic [14:0] dma_src_addr,     // base address of matrix A in SRAM
    output logic [14:0] dma_dst_addr,     // base address of result in SRAM
    output logic [3:0]  dma_row,          // which row is being processed
    input  logic        dma_done          // DMA finished its current transfer
);

    // ── FSM states ────────────────────────────────────────────────────────────
    typedef enum logic [3:0] {
        S_IDLE        = 4'd0,
        S_PROG        = 4'd1,
        S_PROG_HOLD   = 4'd2,
        S_RESET       = 4'd3,
        S_RESET_HOLD  = 4'd4,
        S_WAIT_DMA_IN = 4'd5,
        S_COMPUTE     = 4'd6,
        S_WAIT_DMA_OUT= 4'd7,
        S_DONE        = 4'd8
    } state_t;

    state_t state;

    // ── Internal registers (written by core via AXI) ──────────────────────────
    logic [3:0]         reg_prog_row;
    logic [3:0]         reg_prog_col;
    logic signed [31:0] reg_prog_weight;
    logic [14:0]        reg_src_addr;
    logic [14:0]        reg_dst_addr;

    // ── Status ────────────────────────────────────────────────────────────────
    logic [1:0] status;   // 0=idle  1=busy  2=done  3=error

    // ── Row counter — tracks which row of A we are processing ─────────────────
    logic [3:0] row_cnt;

    // ── AXI write logic ───────────────────────────────────────────────────────
    // We latch the write address and data when both are valid,
    // then process the register write and issue the response.

    logic        aw_captured;
    logic [31:0] aw_addr_lat;   // latched write address
    logic        w_captured;
    logic [31:0] w_data_lat;    // latched write data

    // internal decoded write — goes to register file and FSM trigger
    logic        reg_we;
    logic [7:0]  reg_addr;
    logic [31:0] reg_wdata;

    always_ff @(posedge clk) begin
        if (rst) begin
            aw_captured   <= 1'b0;
            w_captured    <= 1'b0;
            s_axi_awready <= 1'b1;
            s_axi_wready  <= 1'b1;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            reg_we        <= 1'b0;
        end else begin
            reg_we <= 1'b0; // default — only high for one cycle

            // accept write address
            if (s_axi_awvalid && s_axi_awready) begin
                aw_addr_lat   <= s_axi_awaddr;
                aw_captured   <= 1'b1;
                s_axi_awready <= 1'b0;
            end

            // accept write data
            if (s_axi_wvalid && s_axi_wready) begin
                w_data_lat   <= s_axi_wdata;
                w_captured   <= 1'b1;
                s_axi_wready <= 1'b0;
            end

            // both address and data captured — do the write
            if (aw_captured && w_captured) begin
                reg_we      <= 1'b1;
                reg_addr    <= aw_addr_lat[7:0];
                reg_wdata   <= w_data_lat;
                aw_captured <= 1'b0;
                w_captured  <= 1'b0;
                // send write response
                s_axi_bvalid  <= 1'b1;
                s_axi_bresp   <= 2'b00; // OKAY
                // re-open for next transaction
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
            end

            // clear bvalid once core accepts the response
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    // ── AXI read logic ────────────────────────────────────────────────────────
    // Only STATUS is readable. Returns it one cycle after arvalid.

    always_ff @(posedge clk) begin
        if (rst) begin
            s_axi_arready <= 1'b1;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= '0;
            s_axi_rresp   <= 2'b00;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_arready <= 1'b0;
                s_axi_rdata   <= {30'b0, status}; // only STATUS is readable
                s_axi_rresp   <= 2'b00;
                s_axi_rvalid  <= 1'b1;
            end
            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid  <= 1'b0;
                s_axi_arready <= 1'b1;
            end
        end
    end

    // ── Register file (written when reg_we is high) ───────────────────────────
    always_ff @(posedge clk) begin
        if (rst) begin
            reg_prog_row    <= '0;
            reg_prog_col    <= '0;
            reg_prog_weight <= '0;
            reg_src_addr    <= '0;
            reg_dst_addr    <= '0;
        end else if (reg_we) begin
            case (reg_addr)
                8'h00: reg_prog_row    <= reg_wdata[3:0];
                8'h04: reg_prog_col    <= reg_wdata[3:0];
                8'h08: reg_prog_weight <= reg_wdata;
                8'h0C: reg_src_addr    <= reg_wdata[14:0];
                8'h10: reg_dst_addr    <= reg_wdata[14:0];
                default: ; // trigger registers handled in FSM
            endcase
        end
    end

    // ── Main FSM ──────────────────────────────────────────────────────────────
    always_ff @(posedge clk) begin
        if (rst) begin
            state             <= S_IDLE;
            status            <= 2'd0;
            row_cnt           <= '0;
            reram_mode        <= 2'b00;
            reram_prog_row    <= '0;
            reram_prog_col    <= '0;
            reram_prog_weight <= '0;
            dma_trig_in       <= 1'b0;
            dma_trig_out      <= 1'b0;
            dma_src_addr      <= '0;
            dma_dst_addr      <= '0;
            dma_row           <= '0;
        end else begin

            // defaults — pulses only, cleared every cycle unless set below
            reram_mode        <= 2'b00;
            dma_trig_in       <= 1'b0;
            dma_trig_out      <= 1'b0;
            reram_prog_row    <= reg_prog_row;
            reram_prog_col    <= reg_prog_col;
            reram_prog_weight <= reg_prog_weight;

            case (state)

                // ── Wait for core to trigger something ───────────────────────
                S_IDLE: begin
                    status <= 2'd0;
                    if (reg_we) begin
                        case (reg_addr)

                            8'h14: begin // TRIG_PROG
                                reram_prog_row    <= reg_prog_row;
                                reram_prog_col    <= reg_prog_col;
                                reram_prog_weight <= reg_prog_weight;
                                state             <= S_PROG;
                                status            <= 2'd1;
                            end

                            8'h18: begin // TRIG_COMPUTE
                                row_cnt      <= '0;
                                dma_src_addr <= reg_src_addr;
                                dma_dst_addr <= reg_dst_addr;
                                dma_row      <= '0;
                                dma_trig_in  <= 1'b1; // kick off first DMA transfer
                                state        <= S_WAIT_DMA_IN;
                                status       <= 2'd1;
                            end

                            8'h1C: begin // TRIG_RESET
                                state  <= S_RESET;
                                status <= 2'd1;
                            end

                            default: ;
                        endcase
                    end
                end

                // ── Program one cell — pulse PROG for one cycle then hold ────
                S_PROG: begin
                    reram_mode <= 2'b01; // PROG — pulses for exactly one cycle
                    status     <= 2'd2;  // done — held until core writes CLEAR
                    state      <= S_PROG_HOLD;
                end

                // ── Reset all weights — pulse RESET for one cycle then hold ──
                S_RESET: begin
                    reram_mode <= 2'b11; // RESET — pulses for exactly one cycle
                    status     <= 2'd2;  // done — held until core writes CLEAR
                    state      <= S_RESET_HOLD;
                end

                // ── Hold after PROG — wait for core CLEAR ────────────────────
                S_PROG_HOLD: begin
                    if (reg_we && reg_addr == 8'h24)
                        state <= S_IDLE;
                end

                // ── Hold after RESET — wait for core CLEAR ────────────────────
                S_RESET_HOLD: begin
                    if (reg_we && reg_addr == 8'h24)
                        state <= S_IDLE;
                end

                // ── Wait for DMA to finish loading input row into ReRAM ───────
                S_WAIT_DMA_IN: begin
                    if (dma_done) begin
                        reram_mode <= 2'b10; // tell ReRAM to compute
                        state      <= S_COMPUTE;
                    end
                end

                // ── Wait for ReRAM MAC to finish ──────────────────────────────
                S_COMPUTE: begin
                    if (reram_done) begin
                        dma_trig_out <= 1'b1; // tell DMA to save output row
                        state        <= S_WAIT_DMA_OUT;
                    end
                end

                // ── Wait for DMA to finish writing output row to SRAM ─────────
                S_WAIT_DMA_OUT: begin
                    if (dma_done) begin
                        if (row_cnt == 4'd15) begin
                            // all 16 rows done
                            state  <= S_DONE;
                        end else begin
                            // move to next row
                            row_cnt     <= row_cnt + 1;
                            dma_row     <= row_cnt + 1;
                            dma_trig_in <= 1'b1; // load next input row
                            state       <= S_WAIT_DMA_IN;
                        end
                    end
                end

                // ── All done — hold STATUS=done until core clears it ──────────
                S_DONE: begin
                    status <= 2'd2;  // hold here — don't go to IDLE automatically
                    // core clears status by writing to CLEAR register (0x24)
                    if (reg_we && reg_addr == 8'h24)
                        state <= S_IDLE;
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule
