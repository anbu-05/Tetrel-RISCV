module simplemem #(
    parameter MEM_WORDS = 131072, //128KiB (MEM_WORDS * 4 bytes) (till address 0x00020000)
    parameter string PROGRAM_HEX = "../firmware/hex/smoke_test.hex"
) (
    input logic clk, resetn,

    input  logic 		mem_valid,
    input  logic 		mem_instr,
    output logic 		mem_ready,
    input  logic [31:0] mem_addr,
    input  logic [31:0] mem_wdata,
    input  logic [ 3:0] mem_wstrb,
    output logic [31:0] mem_rdata
);

    reg [31:0] memory [0:MEM_WORDS-1];

	always @(posedge clk) begin
		mem_ready <= 0;
		if (mem_valid && !mem_ready) begin
            mem_ready <= 1;
            mem_rdata <= memory[mem_addr >> 2];
            if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
            if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
            if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
            if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
		end
	end

    // if ROM_ORIGIN is non-zero, load hex starting at that offset in the array
    initial begin
        $readmemh(PROGRAM_HEX, memory);
    end
    
endmodule