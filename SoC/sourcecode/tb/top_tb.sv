`timescale 1 ns / 1 ps

module top_tb;

    reg clk = 1;
    reg resetn = 0;

    always #5 clk = ~clk;

    initial begin
        repeat (10) @(posedge clk);
        resetn <= 1;
    end

    top dut(
        .clk(clk),
        .resetn(resetn)
    );

    // Signature region: 0x00017F80 - 0x00017FFF (32 slots)
    localparam SIG_BASE_IDX = 32'h00017F80 >> 2;
    localparam DONE_VAL     = 32'hDEADBEEF;

    // Tap native PicoRV32 bus
    wire        mem_valid = dut.core_mem_valid;
    wire        mem_ready = dut.core_mem_ready;
    wire [31:0] mem_addr  = dut.core_mem_addr;
    wire [ 3:0] mem_wstrb = dut.core_mem_wstrb;

    // Trigger when SIG_DONE (slot 31) is written
    always @(posedge clk) begin
        if (mem_valid && mem_ready && (mem_wstrb != 0) && (mem_addr == 32'h00017FFC)) begin
            $display("[%0t] SIG_DONE written - test completed normally", $time);
            check_signatures();
        end
    end

    // Timeout — prints whatever was written so far
    initial begin
        #10_000_000; // 10ms
        $display("[%0t] TIMEOUT - test did not complete. Partial results:", $time);
        check_signatures();
    end

    task check_signatures;
        integer i;
        reg [31:0] val;
        begin
            $display("---- Signature Results ----");
            for (i = 0; i < 32; i = i + 1) begin
                val = dut.mem.memory[SIG_BASE_IDX + i];

                if (^val === 1'bx)
                    $display("  SIG[%02d] UNUSED", i);
                else if (i == 31 && val == DONE_VAL)
                    $display("  SIG[31] DONE  (0xDEADBEEF)");
                else if (val[31:20] == 12'hBAD)
                    $display("  SIG[%02d] FAIL  (0x%08X)", i, val);
                else
                    $display("  SIG[%02d] PASS  (0x%08X)", i, val);
            end
            $display("---------------------------");
        end
    endtask

endmodule