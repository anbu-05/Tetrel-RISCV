module simplemem_axi_adapter #(
    //
) (
    input logic clk, resetn,

    // AXI4-lite slave memory interface

    axi_interf mem_axi,

    // Native PicoRV32 memory interface (for slave)

	output logic        mem_valid,
	output logic        mem_instr,
	input  logic        mem_ready,
	output logic [31:0] mem_addr,
	output logic [31:0] mem_wdata,
	output logic [ 3:0] mem_wstrb,
	input  logic [31:0] mem_rdata

);

	reg ack_rvalid;
	reg ack_bvalid;

	//write logic
	assign mem_axi.awready = mem_ready;
	assign mem_axi.arready = mem_ready;

	always_comb begin
		if (mem_axi.awvalid) begin
			mem_addr = mem_axi.awaddr;
			mem_valid = mem_axi.awvalid;
		end
		else if (mem_axi.arvalid) begin
			mem_addr = mem_axi.araddr;
			mem_valid = mem_axi.arvalid;
		end
		else begin
			mem_addr = 32'b0;
			mem_valid = 1'b0;
		end
	end

	assign mem_wready = mem_ready;
	assign mem_wdata = mem_axi.wdata;
	assign mem_wstrb = mem_axi.wstrb;

	//read logic
	assign mem_axi.rvalid = ack_rvalid;
	assign mem_axi.rdata = mem_rdata;

	assign mem_axi.bvalid = ack_bvalid;

	always_ff @(posedge clk) begin
		if (!resetn) begin
			ack_rvalid <= 0;
		end else begin
			if (mem_ready && !mem_wstrb)   // memory just finished a read
				ack_rvalid <= 1;
			if (mem_axi.rvalid && mem_axi.rready)  // master consumed the data
				ack_rvalid <= 0;
		end
	end

	always_ff @(posedge clk) begin
		if (!resetn) begin
			ack_bvalid <= 0;
		end else begin
			if (mem_ready && |mem_wstrb)   // memory just finished a write
				ack_bvalid <= 1;
			if (mem_axi.bvalid && mem_axi.bready)  // master got the response
				ack_bvalid <= 0;
		end
	end
endmodule