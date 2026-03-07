// reram_array.sv — 16x16 ReRAM crossbar, 32-bit
//
// mode: 00=idle  01=prog  10=compute  11=reset
// done: pulses HIGH for one cycle when compute result is ready

module reram_array (
    input  logic        clk,
    input  logic        rst,
    input  logic [1:0]  mode,

    // PROG inputs
    input  logic [3:0]         prog_row,
    input  logic [3:0]         prog_col,
    input  logic signed [31:0] prog_weight,

    // COMPUTE inputs/outputs
    input  logic signed [31:0] input_vec  [16],
    output logic signed [31:0] output_vec [16],
    output logic               done
);

    // ── Weight grid (the ReRAM cells) ────────────────────────────────────────
    logic signed [31:0] W [16][16];

    always_ff @(posedge clk) begin
        if (rst || mode == 2'b11)
            foreach (W[i,j]) W[i][j] <= '0;
        else if (mode == 2'b01)
            W[prog_row][prog_col] <= prog_weight;
    end

    // ── Latch input on COMPUTE ────────────────────────────────────────────────
    logic signed [31:0] in_buf [16];

    always_ff @(posedge clk) begin
        if (rst)
            foreach (in_buf[i]) in_buf[i] <= '0;
        else if (mode == 2'b10)
            foreach (in_buf[i]) in_buf[i] <= input_vec[i];
    end

    // ── MAC (combinational) ───────────────────────────────────────────────────
    logic signed [63:0] acc [16];
    logic signed [31:0] sat [16];

    always_comb begin
        foreach (acc[j]) begin
            acc[j] = '0;
            for (int i = 0; i < 16; i++)
                acc[j] += 64'(signed'(in_buf[i])) * 64'(signed'(W[i][j]));

            // clamp to signed 32-bit range
            if      (acc[j] >  64'sd2147483647) sat[j] = 32'sh7fffffff;
            else if (acc[j] < -64'sd2147483648) sat[j] = 32'sh80000000;
            else                                sat[j] = acc[j][31:0];
        end
    end

    // ── Register output, pulse done ──────────────────────────────────────────
    logic delay;

    always_ff @(posedge clk) begin
        if (rst) delay <= '0;
        else     delay <= (mode == 2'b10);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            foreach (output_vec[j]) output_vec[j] <= '0;
            done <= '0;
        end else begin
            done <= delay;
            if (delay)
                foreach (output_vec[j]) output_vec[j] <= sat[j];
        end
    end

endmodule
