module simplemem_axi_adapter #(
    //
) (
    input logic clk, resetn,

    // AXI4-lite slave memory interface

    axi_interf mem_axi,

    // Native PicoRV32 memory interface (for slave)

	output logic        mem_valid, //
	output logic        mem_instr,
	input  logic        mem_ready, //
	output logic [31:0] mem_addr, //
	output logic [31:0] mem_wdata, //
	output logic [ 3:0] mem_wstrb, //
	input  logic [31:0] mem_rdata //

);

	reg ack_rvalid;
	reg xfer_done;

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

	always_ff @(posedge clk) begin
		if (!resetn) begin 
			ack_rvalid <= 0;
		end else begin 
			xfer_done <= mem_valid && mem_ready;
			if (mem_axi.rvalid && mem_axi.rready) ack_rvalid <= 1;
			if (xfer_done || !mem_ready) ack_rvalid <= 0;
		end
	end
endmodule