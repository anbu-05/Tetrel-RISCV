module simpleuart_axi_adapter #(
    parameter MEM_WORDS = 4,
    parameter REG_ORIGIN = 32'h00018000,
    parameter REG_LENGTH = 32'h0000000c
) (
    input logic clk, resetn,

	// AXI4-lite slave memory interface

	axi_interf.slave uart_axi,

    //simpleuart interface

	input  logic        ser_tx,
	output logic        ser_rx,

	output logic [ 3:0] reg_div_we,
	output logic [31:0] reg_div_di,
	input  logic [31:0] reg_div_do,

	output logic        reg_dat_we,
	output logic        reg_dat_re,
	output logic [31:0] reg_dat_di,
	input  logic [31:0] reg_dat_do,
	input  logic        reg_dat_wait
);

    reg [31:0] memory [0:MEM_WORDS-1];

//---------uart module buffers---------
logic [31:0] uart_div_do_buffer;
logic [31:0] uart_dat_do_buffer;

logic debug = 0;

//---wait feedback to core---
assign memory[0][0] = !reg_dat_wait; //TX_READY


//---------axi read logic---------

	logic [31:0] mem_read_buffer;
	logic [31:0] mem_read_addr_buffer;
	logic [$clog2(MEM_WORDS)-1:0] read_word_index;
	typedef enum logic [1:0] {read_capture, load, hold} read_state_t;
	read_state_t read_fsm;

	reg [31:0] read_memory_buffer [0:MEM_WORDS-1];

	always_ff @(posedge clk or negedge resetn) begin : read_logic
		if (!resetn) begin 
			mem_read_buffer <= 0;
			mem_read_addr_buffer <= 0;
			uart_axi.rvalid <= 0;
			uart_axi.rdata <= 0;
			uart_axi.arready <= 1; //note, you'll need to control arready even during write logic, hence im not setting it to anything in the read_capture fsm
			//further note: the fsm wont move on from read_capture state unless you reset it once. this is because arread is left floating till reset is applied
			read_fsm <= read_capture;

			read_word_index <= 0;

			//---initializing uart module---

			ser_rx <= 1;
			reg_dat_re <= 0;

		end else begin 
			case (read_fsm)
				read_capture: begin 
					uart_axi.rvalid <= 0;
					uart_axi.rdata <= 0;
					//maybe add uart_axi.arready <= 1; if youre facing problems when using the memory without resetting
					
					ser_rx <= 1;
					reg_dat_re <= 0;

					if (uart_axi.arvalid && uart_axi.arready) begin
						mem_read_addr_buffer <= uart_axi.araddr;
						read_fsm <= load;
					end
				end

				load: begin 
					uart_axi.rvalid <= 0;
					uart_axi.rdata <= 0;

					//note: do this word_index dance in write logic too

					if ((mem_read_addr_buffer >= REG_ORIGIN && mem_read_addr_buffer < REG_ORIGIN + REG_LENGTH)) begin

						read_word_index = (mem_read_addr_buffer) >> 2;

						if (read_word_index < MEM_WORDS) begin 
							mem_read_buffer <= memory[read_word_index];

                        //---------uart receive logic---------
                            uart_div_do_buffer <= reg_div_do;

                            if (reg_dat_re) begin 
                                uart_dat_do_buffer <= reg_dat_do;
                            end
                            
                            read_fsm <= hold;
						end else read_fsm <= read_capture;

						uart_axi.arready <= 0;
					end else begin 
						read_fsm <= read_capture;
						uart_axi.arready <= 1;
					end
				end

				hold: begin 
					uart_axi.rvalid <= 1;
					uart_axi.rdata <= mem_read_buffer;
					if (uart_axi.rready) begin
						read_fsm <= read_capture;
						uart_axi.arready <= 1;
					end
				end

				default: read_fsm <= read_capture;
			endcase
		end
	end

//---------axi write logic---------

	//note: picorv32 does not have a bresp channel. it doesnt have the full implementation of axi lite

	logic [31:0] mem_write_buffer;
	logic [31:0] mem_write_addr_buffer;
	logic [$clog2(MEM_WORDS)-1:0] write_word_index;
	typedef enum logic [1:0] {write_capture, store, respond} write_state_t;
	write_state_t write_fsm;

	always_ff @(posedge clk or negedge resetn) begin : write_logic
		if (!resetn) begin 
			mem_write_buffer <= 0;
			mem_write_addr_buffer <= 0;
			uart_axi.awready <= 1;
			uart_axi.wready <= 0;
			write_fsm <= write_capture;

			write_word_index <= 0;

			//---initializing uart module---

			reg_div_di <= 0;
			reg_div_we <= 0;
			reg_dat_we <= 0;
			reg_dat_di <= 0;

		end else begin 
			case (write_fsm)
				write_capture: begin 
					uart_axi.bvalid <= 0;

					reg_div_we <= 0;
					reg_dat_we <= 0;

					if (uart_axi.awvalid && uart_axi.awready) begin
						uart_axi.wready <= 1;
						mem_write_addr_buffer <= uart_axi.awaddr;
						write_fsm <= store;
					end
				end

				store: begin
						if (uart_axi.wvalid && uart_axi.wready) begin
							if ((mem_write_addr_buffer >= REG_ORIGIN && mem_write_addr_buffer < REG_ORIGIN + REG_LENGTH)) begin

								write_word_index = (mem_write_addr_buffer) >> 2;

								if (write_word_index < MEM_WORDS) begin 
									//---------uart transmit logic---------
									if (write_word_index == 1 && !reg_dat_wait) begin 
										reg_div_di <= uart_axi.wdata;
										reg_div_we <= uart_axi.wstrb;
										write_fsm <= respond;
									end else if (write_word_index == 2 && !reg_dat_wait) begin
										reg_dat_di <= uart_axi.wdata;
										reg_dat_we <= 1;
										write_fsm <= respond;
									end else begin
										write_fsm <= store;
									end
								end else write_fsm <= write_capture;
                            end else begin 
								write_fsm <= write_capture;
							end
						end else if (uart_axi.awvalid && uart_axi.awready) write_fsm <= store;
						else write_fsm <= write_capture;
					end

				respond: begin
						uart_axi.bvalid <= 1;
						uart_axi.wready <= 0;

						if (!reg_dat_wait) begin
							reg_div_we <= 0;
							reg_dat_we <= 0;		
							write_fsm <= write_capture;
						end else write_fsm <= respond;
					end

				default: write_fsm <= write_capture;
			endcase
		end
	end

endmodule