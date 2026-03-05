module top (
    input  logic clk,
    input  logic resetn
);
//---------declarations---------
    // Native PicoRV32 memory interface
    wire        core_mem_valid;
    wire        core_mem_instr;
    wire [31:0] core_mem_addr;
    wire [31:0] core_mem_wdata;
    wire [ 3:0] core_mem_wstrb;
    wire [31:0] core_mem_rdata;
    wire        core_mem_ready;

    // simple mem memory interface
    wire        memory_mem_valid;
    wire        memory_mem_instr;
    wire [31:0] memory_mem_addr;
    wire [31:0] memory_mem_wdata;
    wire [ 3:0] memory_mem_wstrb;
    wire [31:0] memory_mem_rdata;
    wire        memory_mem_ready;

    //simpleuart interface
	wire        ser_tx;
	wire        ser_rx;

	wire [ 3:0]  reg_div_we;
	wire [31:0] reg_div_di;
	wire [31:0] reg_div_do;

	wire         reg_dat_we;
	wire         reg_dat_re;
	wire [31:0]  reg_dat_di;
	wire [31:0]  reg_dat_do;
	wire         reg_dat_wait;

//---------interface instantiations---------
    // AXI4-Lite interface signals
    axi_interf mem_axi();

//---------instantiations---------
    // PicoRV32 core
    picorv32 core (
        .clk        (clk),
        .resetn     (resetn),
        .mem_valid  (core_mem_valid),
        .mem_instr  (core_mem_instr),
        .mem_ready  (core_mem_ready),
        .mem_addr   (core_mem_addr),
        .mem_wdata  (core_mem_wdata),
        .mem_wstrb  (core_mem_wstrb),
        .mem_rdata  (core_mem_rdata)
    );

    
    // PicoRV32 AXI adapter
    picorv32_axi_adapter axi_adapter (
        // Native interface
        .clk        (clk),
        .resetn     (resetn),
        .mem_valid  (core_mem_valid),
        .mem_instr  (core_mem_instr),
        .mem_ready  (core_mem_ready),
        .mem_addr   (core_mem_addr),
        .mem_wdata  (core_mem_wdata),
        .mem_wstrb  (core_mem_wstrb),
        .mem_rdata  (core_mem_rdata),

        //AXI interface
            //Write Address Channel
        .mem_axi_awvalid (mem_axi.awvalid),
        .mem_axi_awready (mem_axi.awready),
        .mem_axi_awaddr  (mem_axi.awaddr),
        .mem_axi_awprot  (mem_axi.awprot),
            //Write Data Channel
        .mem_axi_wvalid  (mem_axi.wvalid),
        .mem_axi_wready  (mem_axi.wready),
        .mem_axi_wdata   (mem_axi.wdata),
        .mem_axi_wstrb   (mem_axi.wstrb),
            //Write Response Channel
        .mem_axi_bvalid  (mem_axi.bvalid),
        .mem_axi_bready  (mem_axi.bready),
            //Read Address Channel
        .mem_axi_arvalid (mem_axi.arvalid),
        .mem_axi_arready (mem_axi.arready),
        .mem_axi_araddr  (mem_axi.araddr),
        .mem_axi_arprot  (mem_axi.arprot),
            //Read Data Channel
        .mem_axi_rvalid  (mem_axi.rvalid),
        .mem_axi_rready  (mem_axi.rready),
        .mem_axi_rdata   (mem_axi.rdata)
    );

    //simple memory AXI adapter
    simplemem_axi_adapter mem_adapter (
        .clk        (clk),
        .resetn     (resetn),

        //AXI interface
        .mem_axi(mem_axi.slave),

        // Native memory interface
        .mem_valid  (memory_mem_valid),
        .mem_instr  (memory_mem_instr),
        .mem_ready  (memory_mem_ready),
        .mem_addr   (memory_mem_addr),
        .mem_wdata  (memory_mem_wdata),
        .mem_wstrb  (memory_mem_wstrb),
        .mem_rdata  (memory_mem_rdata)
    );

    //simple memory module
    simplemem #(
        .PROGRAM_HEX("../hex/smoke_test.hex")
    ) mem (
        .clk        (clk),
        .resetn     (resetn),

        // Native memory interface
        .mem_valid  (memory_mem_valid),
        .mem_instr  (memory_mem_instr),
        .mem_ready  (memory_mem_ready),
        .mem_addr   (memory_mem_addr),
        .mem_wdata  (memory_mem_wdata),
        .mem_wstrb  (memory_mem_wstrb),
        .mem_rdata  (memory_mem_rdata)
    );

endmodule
