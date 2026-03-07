// =============================================================================
// imc_memory_block.sv
//
// Single AXI4-Lite slave covering the entire IMC subsystem.
// The CPU uses one address region (slave 3) for everything:
//
//   OFFSET 0x00000 - 0x00027  ->  imc_peripheral registers
//   OFFSET 0x00028 - 0x20027  ->  imc_sram data (128 KB, word-addressed)
//
// The interconnect subtracts SLAVE3_ORIGIN before sending the address here,
// so all addresses arriving at imc_axi are already offsets from 0.
//
// top.sv must set:
//   SLAVE3_ORIGIN = 32'h00030000
//   SLAVE3_LENGTH = 32'h00020040
//
// AXI ROUTING APPROACH:
//   Instead of a mux that tries to remember which slave to route responses to
//   (which breaks when awaddr goes away after the handshake), each slave just
//   gates its own ready signals based on the address. Only one slave accepts
//   each transaction. Responses are OR'd together — only one will ever be
//   non-zero at a time since transactions are serialised by PicoRV32.
//
//   This is the same pattern simplemem_axi_adapter uses.
//
// SRAM WORD ADDRESS from CPU:
//   word address = (axi_offset - 0x28) >> 2
//
// SRC_ADDR / DST_ADDR are 15-bit WORD addresses into imc_sram:
//   matrix A at word 0, results at word 256
//
// DMA ARBITRATION:
//   DMA always wins. CPU bridge stalls (ready=0) while DMA is active.
//
// RESET: active-HIGH. top.sv passes (!resetn).
// =============================================================================

module imc_memory_block (
    input  logic clk,
    input  logic reset,

    axi_interf imc_axi
);

    // =========================================================================
    // Internal wires
    // =========================================================================

    logic [1:0]         reram_mode;
    logic [3:0]         reram_prog_row;
    logic [3:0]         reram_prog_col;
    logic signed [31:0] reram_prog_weight;
    logic               reram_done;

    logic signed [31:0] reram_input_vec  [16];
    logic signed [31:0] reram_output_vec [16];

    logic        dma_trig_in;
    logic        dma_trig_out;
    logic [14:0] dma_src_addr;
    logic [14:0] dma_dst_addr;
    logic [3:0]  dma_row;
    logic        dma_done;

    logic [14:0]        dma_sram_addr;
    logic signed [31:0] dma_sram_wdata;
    logic               dma_sram_we;

    logic [14:0]        sram_addr;
    logic signed [31:0] sram_wdata;
    logic               sram_we;
    logic signed [31:0] sram_rdata;

    // =========================================================================
    // Address decode (combinational — only used for ready gating on AW/AR/W,
    // where the address is guaranteed valid. Response routing uses OR not mux.)
    // =========================================================================

    logic this_is_periph_w;   // current write address targets peripheral
    logic this_is_sram_w;     // current write address targets SRAM
    logic this_is_periph_r;   // current read address targets peripheral
    logic this_is_sram_r;     // current read address targets SRAM

    assign this_is_periph_w = (imc_axi.awaddr < 32'h28);
    assign this_is_sram_w   = (imc_axi.awaddr >= 32'h28);
    assign this_is_periph_r = (imc_axi.araddr < 32'h28);
    assign this_is_sram_r   = (imc_axi.araddr >= 32'h28);

    // =========================================================================
    // Peripheral-side AXI wires
    // Peripheral only sees the transaction if the address is in its range.
    // =========================================================================

    logic        periph_awvalid; logic        periph_awready;
    logic [31:0] periph_awaddr;
    logic        periph_wvalid;  logic        periph_wready;
    logic [31:0] periph_wdata;   logic [3:0]  periph_wstrb;
    logic        periph_bvalid;  logic        periph_bready;
    logic [1:0]  periph_bresp;
    logic        periph_arvalid; logic        periph_arready;
    logic [31:0] periph_araddr;
    logic [31:0] periph_rdata;   logic [1:0]  periph_rresp;
    logic        periph_rvalid;  logic        periph_rready;

    assign periph_awvalid = imc_axi.awvalid & this_is_periph_w;
    assign periph_awaddr  = imc_axi.awaddr;
    assign periph_wvalid  = imc_axi.wvalid  & this_is_periph_w;
    assign periph_wdata   = imc_axi.wdata;
    assign periph_wstrb   = imc_axi.wstrb;
    assign periph_bready  = imc_axi.bready;
    assign periph_arvalid = imc_axi.arvalid & this_is_periph_r;
    assign periph_araddr  = imc_axi.araddr;
    assign periph_rready  = imc_axi.rready;

    // =========================================================================
    // SRAM bridge-side AXI wires
    // Bridge only sees the transaction if the address is in SRAM range.
    // =========================================================================

    logic        sram_cpu_awvalid; logic sram_cpu_awready;
    logic [31:0] sram_cpu_awaddr;
    logic        sram_cpu_wvalid;  logic sram_cpu_wready;
    logic [31:0] sram_cpu_wdata;
    logic        sram_cpu_bvalid;
    logic        sram_cpu_arvalid; logic sram_cpu_arready;
    logic [31:0] sram_cpu_araddr;
    logic        sram_cpu_rvalid;
    logic [31:0] sram_cpu_rdata;

    assign sram_cpu_awvalid = imc_axi.awvalid & this_is_sram_w;
    assign sram_cpu_awaddr  = imc_axi.awaddr;
    assign sram_cpu_wvalid  = imc_axi.wvalid  & this_is_sram_w;
    assign sram_cpu_wdata   = imc_axi.wdata;
    assign sram_cpu_arvalid = imc_axi.arvalid & this_is_sram_r;
    assign sram_cpu_araddr  = imc_axi.araddr;

    // =========================================================================
    // AXI response routing — OR pattern (only one slave responds at a time)
    // =========================================================================

    assign imc_axi.awready = periph_awready | sram_cpu_awready;
    assign imc_axi.wready  = periph_wready  | sram_cpu_wready;
    assign imc_axi.bvalid  = periph_bvalid  | sram_cpu_bvalid;
    assign imc_axi.arready = periph_arready | sram_cpu_arready;
    assign imc_axi.rvalid  = periph_rvalid  | sram_cpu_rvalid;
    assign imc_axi.rdata   = periph_rvalid  ? periph_rdata : sram_cpu_rdata;

    // =========================================================================
    // DMA active tracker
    // =========================================================================

    logic dma_active;

    always_ff @(posedge clk) begin
        if (reset)
            dma_active <= 1'b0;
        else begin
            if (dma_trig_in || dma_trig_out)
                dma_active <= 1'b1;
            if (dma_done)
                dma_active <= 1'b0;
        end
    end

    // =========================================================================
    // CPU AXI-to-SRAM bridge
    //
    // Accepts AXI writes/reads only when address is in SRAM range AND DMA idle.
    // Word address = (axi_offset - 0x28) >> 2
    // Fires bvalid/rvalid directly — no mux needed, OR'd at top level.
    // =========================================================================

    logic        cpu_aw_captured;
    logic [14:0] cpu_aw_word_addr;
    logic        cpu_w_captured;
    logic [31:0] cpu_w_data_lat;
    logic        cpu_bvalid_r;
    logic        cpu_rvalid_r;
    logic [31:0] cpu_rdata_r;
    logic        cpu_read_pending;
    logic [14:0] cpu_sram_addr;   // write address
    logic [14:0] cpu_sram_raddr;  // read address (separate — must not share with write)
    logic [31:0] cpu_sram_wdata;
    logic        cpu_sram_we;

    always_ff @(posedge clk) begin
        if (reset) begin
            cpu_aw_captured  <= 1'b0;
            cpu_w_captured   <= 1'b0;
            cpu_bvalid_r     <= 1'b0;
            cpu_rvalid_r     <= 1'b0;
            cpu_rdata_r      <= '0;
            cpu_sram_we      <= 1'b0;
            cpu_read_pending <= 1'b0;
            cpu_sram_addr    <= '0;
            cpu_sram_raddr   <= '0;
            cpu_sram_wdata   <= '0;
            cpu_aw_word_addr <= '0;
            cpu_w_data_lat   <= '0;
        end else begin

            cpu_sram_we <= 1'b0;

            if (sram_cpu_awvalid && sram_cpu_awready) begin
                cpu_aw_word_addr <= (sram_cpu_awaddr - 32'h28) >> 2;
                cpu_aw_captured  <= 1'b1;
            end

            if (sram_cpu_wvalid && sram_cpu_wready) begin
                cpu_w_data_lat <= sram_cpu_wdata;
                cpu_w_captured <= 1'b1;
            end

            if (cpu_aw_captured && cpu_w_captured && !dma_active) begin
                cpu_sram_addr   <= cpu_aw_word_addr;
                cpu_sram_wdata  <= cpu_w_data_lat;
                cpu_sram_we     <= 1'b1;
                cpu_aw_captured <= 1'b0;
                cpu_w_captured  <= 1'b0;
                cpu_bvalid_r    <= 1'b1;
            end

            if (cpu_bvalid_r && imc_axi.bready)
                cpu_bvalid_r <= 1'b0;

            if (sram_cpu_arvalid && sram_cpu_arready) begin
                cpu_sram_raddr   <= (sram_cpu_araddr - 32'h28) >> 2;
                cpu_read_pending <= 1'b1;
            end

            if (cpu_read_pending && !dma_active) begin
                cpu_rdata_r      <= sram_rdata;
                cpu_rvalid_r     <= 1'b1;
                cpu_read_pending <= 1'b0;
            end

            if (cpu_rvalid_r && imc_axi.rready)
                cpu_rvalid_r <= 1'b0;

        end
    end

    assign sram_cpu_awready = !dma_active && !cpu_aw_captured;
    assign sram_cpu_wready  = !dma_active && !cpu_w_captured;
    assign sram_cpu_arready = !dma_active && !cpu_read_pending && !cpu_rvalid_r;
    assign sram_cpu_bvalid  = cpu_bvalid_r;
    assign sram_cpu_rvalid  = cpu_rvalid_r;
    assign sram_cpu_rdata   = cpu_rdata_r;

    // =========================================================================
    // SRAM arbiter: DMA wins, CPU is fallback
    // =========================================================================

    // Use read address when a read is pending, write address otherwise
    assign sram_addr  = dma_active ? dma_sram_addr : (cpu_read_pending ? cpu_sram_raddr : cpu_sram_addr);
    assign sram_wdata = dma_active ? dma_sram_wdata : cpu_sram_wdata;
    assign sram_we    = dma_active ? dma_sram_we    : cpu_sram_we;

    // =========================================================================
    // imc_peripheral
    // =========================================================================

    imc_peripheral u_peripheral (
        .clk               (clk),
        .rst               (reset),

        .s_axi_awaddr      (periph_awaddr),
        .s_axi_awvalid     (periph_awvalid),
        .s_axi_awready     (periph_awready),
        .s_axi_wdata       (periph_wdata),
        .s_axi_wstrb       (periph_wstrb),
        .s_axi_wvalid      (periph_wvalid),
        .s_axi_wready      (periph_wready),
        .s_axi_bresp       (periph_bresp),
        .s_axi_bvalid      (periph_bvalid),
        .s_axi_bready      (periph_bready),
        .s_axi_araddr      (periph_araddr),
        .s_axi_arvalid     (periph_arvalid),
        .s_axi_arready     (periph_arready),
        .s_axi_rdata       (periph_rdata),
        .s_axi_rresp       (periph_rresp),
        .s_axi_rvalid      (periph_rvalid),
        .s_axi_rready      (periph_rready),

        .reram_mode        (reram_mode),
        .reram_prog_row    (reram_prog_row),
        .reram_prog_col    (reram_prog_col),
        .reram_prog_weight (reram_prog_weight),
        .reram_done        (reram_done),

        .dma_trig_in       (dma_trig_in),
        .dma_trig_out      (dma_trig_out),
        .dma_src_addr      (dma_src_addr),
        .dma_dst_addr      (dma_dst_addr),
        .dma_row           (dma_row),
        .dma_done          (dma_done)
    );

    // =========================================================================
    // reram_array
    // =========================================================================

    reram_array u_reram (
        .clk              (clk),
        .rst              (reset),
        .mode             (reram_mode),
        .prog_row         (reram_prog_row),
        .prog_col         (reram_prog_col),
        .prog_weight      (reram_prog_weight),
        .input_vec        (reram_input_vec),
        .output_vec       (reram_output_vec),
        .done             (reram_done)
    );

    // =========================================================================
    // imc_dma
    // =========================================================================

    imc_dma u_dma (
        .clk              (clk),
        .rst              (reset),

        .trig_in          (dma_trig_in),
        .trig_out         (dma_trig_out),
        .src_addr         (dma_src_addr),
        .dst_addr         (dma_dst_addr),
        .row              (dma_row),
        .dma_done         (dma_done),

        .input_vec        (reram_input_vec),
        .output_vec       (reram_output_vec),

        .sram_addr        (dma_sram_addr),
        .sram_wdata       (dma_sram_wdata),
        .sram_we          (dma_sram_we),
        .sram_rdata       (sram_rdata)
    );

    // =========================================================================
    // imc_sram
    // =========================================================================

    imc_sram u_sram (
        .clk              (clk),
        .addr             (sram_addr),
        .wdata            (sram_wdata),
        .we               (sram_we),
        .rdata            (sram_rdata)
    );

endmodule