module simple_mem #(
    parameter MEM_WORDS = 131072, //128KiB (MEM_WORDS * 4 bytes) (till address 0x00020000)
    parameter ROM_ORIGIN = 32'h00000000,
    parameter ROM_LENGTH = 32'h00010000, // 64 KiB
    parameter RAM_ORIGIN = 32'h00010000,
    parameter RAM_LENGTH = 32'h00008000, // 32 KiB
    parameter string PROGRAM_HEX = "../hex/smoke_test.hex"
) (
    input logic clk, resetn,

    input  logic 		mem_valid, //
    input  logic 		mem_instr,
    output logic 		mem_ready, //
    input  logic [31:0] mem_addr, //
    input  logic [31:0] mem_wdata, //
    input  logic [ 3:0] mem_wstrb,
    output logic [31:0] mem_rdata //
);

    reg [31:0] memory [0:MEM_WORDS-1];

    localparam logic [31:0] MEM_BASE = (ROM_ORIGIN < RAM_ORIGIN) ? ROM_ORIGIN : RAM_ORIGIN;

	always @(posedge clk) begin
		mem_ready <= 0;
		if (mem_valid && !mem_ready) begin
			if ((mem_addr >= ROM_ORIGIN && mem_addr < ROM_ORIGIN + ROM_LENGTH) || 
                (mem_addr >= RAM_ORIGIN && mem_addr < RAM_ORIGIN + RAM_LENGTH)) begin
                
                integer word_index;
                word_index = (mem_addr - MEM_BASE) >> 2;

                if (word_index >= 0 && word_index < MEM_WORDS) begin 
                    mem_ready <= 1;
                    mem_rdata <= memory[mem_addr >> 2];
                    if (mem_wstrb[0]) memory[word_index][ 7: 0] <= mem_wdata[ 7: 0];
                    if (mem_wstrb[1]) memory[word_index][15: 8] <= mem_wdata[15: 8];
                    if (mem_wstrb[2]) memory[word_index][23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) memory[word_index][31:24] <= mem_wdata[31:24];
                end
			end
			/* add memory-mapped IO here */
		end
	end

    // if ROM_ORIGIN is non-zero, load hex starting at that offset in the array
    initial begin
        if (ROM_ORIGIN == MEM_BASE)
            $readmemh(PROGRAM_HEX, memory);
        else begin
            integer rom_index;
            rom_index = (ROM_ORIGIN - MEM_BASE) >> 2;
            $readmemh(PROGRAM_HEX, memory, rom_index);
        end
    end
    
endmodule