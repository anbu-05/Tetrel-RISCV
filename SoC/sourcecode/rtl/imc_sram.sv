// =============================================================================
// imc_sram.sv
//
// A simple synchronous single-port SRAM dedicated to the IMC block.
// 128KB total = 32768 words x 32 bits. Word-addressed (15-bit index).
//
// Intentionally minimal — no AXI, no ROM/RAM split, no hex preload,
// no byte enables. The DMA is the only master and always does full
// 32-bit word accesses, so none of that complexity is needed.
//
// TIMING:
//   Write : data written on the rising edge when we=1.
//   Read  : rdata is registered — valid the cycle AFTER addr is presented.
//           The DMA FSM accounts for this 1-cycle read latency.
//
// =============================================================================

module imc_sram #(
    parameter DEPTH = 32768  // 32K words = 128 KB
)(
    input  logic clk,

    input  logic [14:0]        addr,
    input  logic signed [31:0] wdata,
    input  logic               we,
    output logic signed [31:0] rdata
);

    logic signed [31:0] mem [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (we)
            mem[addr] <= wdata;
        rdata <= mem[addr];
    end

endmodule
