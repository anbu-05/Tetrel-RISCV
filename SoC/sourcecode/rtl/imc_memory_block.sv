// =============================================================================
// imc_memory_block.sv
//
// WHAT THIS IS:
//   The top-level module that wires together the three components:
//     1. imc_peripheral  — AXI4-Lite slave, FSM, talks to ReRAM and DMA
//     2. reram_array     — 16x16 weight grid, does the MAC
//     3. sram_block      — 128KB storage, two ports (DMA + spare)
//
// WHAT GOES IN AND OUT:
//   In  — AXI4-Lite bus from the RISC-V core
//   In  — DMA handshake signals (done, and the row/address info)
//   Out — DMA trigger signals (trig_in, trig_out, src/dst addresses)
//   In/Out — SRAM Port A (DMA talks directly to SRAM)
//
// INTERNAL CONNECTIONS (not visible outside this module):
//   peripheral ──► reram_array   (mode, prog_*, input_vec)
//   reram_array ──► peripheral   (done, output_vec)
//
// NOTE ON SRAM:
//   Port A is exposed directly to the DMA — the DMA owns bulk data movement.
//   Port B is unused for now — reserved for future use.
//
// =============================================================================

module imc_memory_block (
    input  logic clk,
    input  logic rst,

    // ── AXI4-Lite slave — core talks to peripheral through here ──────────────
    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // ── DMA interface — peripheral orchestrates, DMA executes ────────────────
    output logic        dma_trig_in,    // tell DMA: load next input row → ReRAM
    output logic        dma_trig_out,   // tell DMA: save output row → SRAM
    output logic [14:0] dma_src_addr,   // base address of matrix A in SRAM
    output logic [14:0] dma_dst_addr,   // base address of result in SRAM
    output logic [3:0]  dma_row,        // which row is currently being processed
    input  logic        dma_done,       // DMA signals it has finished

    // ── SRAM Port A — exposed directly to DMA ────────────────────────────────
    input  logic [14:0]        dma_sram_addr,
    input  logic signed [31:0] dma_sram_wdata,
    input  logic               dma_sram_we,
    output logic signed [31:0] dma_sram_rdata,

    // ── ReRAM input vector — driven by DMA directly ───────────────────────────
    // DMA loads one row of matrix A here before each compute cycle
    input  logic signed [31:0] dma_reram_input_vec [16]
);

    // ── Internal wires — peripheral ↔ ReRAM ──────────────────────────────────
    logic [1:0]         reram_mode;
    logic [3:0]         reram_prog_row;
    logic [3:0]         reram_prog_col;
    logic signed [31:0] reram_prog_weight;
    logic signed [31:0] reram_output_vec [16];
    logic               reram_done;

    // DMA drives input_vec directly — wired straight through
    // peripheral does NOT touch this — DMA loads it before each compute
    logic signed [31:0] reram_input_vec [16];
    assign reram_input_vec = dma_reram_input_vec;

    // ── IMC Peripheral ────────────────────────────────────────────────────────
    imc_peripheral u_peripheral (
        .clk              (clk),
        .rst              (rst),

        // AXI4-Lite
        .s_axi_awaddr     (s_axi_awaddr),
        .s_axi_awvalid    (s_axi_awvalid),
        .s_axi_awready    (s_axi_awready),
        .s_axi_wdata      (s_axi_wdata),
        .s_axi_wstrb      (s_axi_wstrb),
        .s_axi_wvalid     (s_axi_wvalid),
        .s_axi_wready     (s_axi_wready),
        .s_axi_bresp      (s_axi_bresp),
        .s_axi_bvalid     (s_axi_bvalid),
        .s_axi_bready     (s_axi_bready),
        .s_axi_araddr     (s_axi_araddr),
        .s_axi_arvalid    (s_axi_arvalid),
        .s_axi_arready    (s_axi_arready),
        .s_axi_rdata      (s_axi_rdata),
        .s_axi_rresp      (s_axi_rresp),
        .s_axi_rvalid     (s_axi_rvalid),
        .s_axi_rready     (s_axi_rready),

        // ReRAM control
        .reram_mode       (reram_mode),
        .reram_prog_row   (reram_prog_row),
        .reram_prog_col   (reram_prog_col),
        .reram_prog_weight(reram_prog_weight),
        .reram_done       (reram_done),

        // DMA handshake
        .dma_trig_in      (dma_trig_in),
        .dma_trig_out     (dma_trig_out),
        .dma_src_addr     (dma_src_addr),
        .dma_dst_addr     (dma_dst_addr),
        .dma_row          (dma_row),
        .dma_done         (dma_done)
    );

    // ── ReRAM Array ───────────────────────────────────────────────────────────
    reram_array u_reram (
        .clk              (clk),
        .rst              (rst),
        .mode             (reram_mode),
        .prog_row         (reram_prog_row),
        .prog_col         (reram_prog_col),
        .prog_weight      (reram_prog_weight),
        .input_vec        (reram_input_vec),
        .output_vec       (reram_output_vec),
        .done             (reram_done)
    );

    // ── SRAM Block ────────────────────────────────────────────────────────────
    sram_block u_sram (
        .clk              (clk),

        // Port A — DMA owns this
        .a_addr           (dma_sram_addr),
        .a_wdata          (dma_sram_wdata),
        .a_we             (dma_sram_we),
        .a_rdata          (dma_sram_rdata),

        // Port B — unused for now, tied off
        .b_addr           (15'b0),
        .b_wdata          (32'b0),
        .b_we             (1'b0),
        .b_rdata          ()       // left unconnected
    );

endmodule
