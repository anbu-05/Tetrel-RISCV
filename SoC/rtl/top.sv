module top_uart_axi (
    input  logic clk,
    input  logic resetn
);
//---------declarations---------
    // Native PicoRV32 memory interface
    wire        mem_valid;
    wire        mem_instr;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [ 3:0] mem_wstrb;
    wire [31:0] mem_rdata;
    wire        mem_ready;

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
    axi_interf picorv32_axi();
    axi_interf mem_axi();
    axi_interf uart_axi();

//---------instantiations---------
    // PicoRV32 core
    picorv32 core (
        .clk        (clk),
        .resetn     (resetn),
        .mem_valid  (mem_valid),
        .mem_instr  (mem_instr),
        .mem_ready  (mem_ready),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (mem_rdata)
    );

    // PicoRV32 AXI adapter
    picorv32_axi_adapter axi_adapter (
        // Native interface
        .clk        (clk),
        .resetn     (resetn),
        .mem_valid  (mem_valid),
        .mem_instr  (mem_instr),
        .mem_ready  (mem_ready),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (mem_rdata),

        //AXI interface
            //Write Address Channel
        .mem_axi_awvalid (picorv32_axi.master.awvalid),
        .mem_axi_awready (picorv32_axi.master.awready),
        .mem_axi_awaddr  (picorv32_axi.master.awaddr),
        .mem_axi_awprot  (picorv32_axi.master.awprot),
            //Write Data Channel
        .mem_axi_wvalid  (picorv32_axi.master.wvalid),
        .mem_axi_wready  (picorv32_axi.master.wready),
        .mem_axi_wdata   (picorv32_axi.master.wdata),
        .mem_axi_wstrb   (picorv32_axi.master.wstrb),
            //Write Response Channel
        .mem_axi_bvalid  (picorv32_axi.master.bvalid),
        .mem_axi_bready  (picorv32_axi.master.bready),
            //Read Address Channel
        .mem_axi_arvalid (picorv32_axi.master.arvalid),
        .mem_axi_arready (picorv32_axi.master.arready),
        .mem_axi_araddr  (picorv32_axi.master.araddr),
        .mem_axi_arprot  (picorv32_axi.master.arprot),
            //Read Data Channel
        .mem_axi_rvalid  (picorv32_axi.master.rvalid),
        .mem_axi_rready  (picorv32_axi.master.rready),
        .mem_axi_rdata   (picorv32_axi.master.rdata)
    );

    // AXI mux to interface with multiple slaves
    axi_mux mux (
        .master_axi(picorv32_axi.master),
        .slave0_axi(mem_axi.slave),
        .slave1_axi(uart_axi.slave)
    );

    // AXI based simple memory module
    simple_mem #(
        .PROGRAM_HEX("../hex/uart_smoke_test.hex")
    ) mem (
        .clk        (clk),
        .resetn     (resetn),

        //AXI interface
        .mem_axi(mem_axi.slave)
    );

    //uart AXI adapter
    simpleuart_axi_adapter uart_adapter (
        .clk        (clk),
        .resetn     (resetn),

        //AXI interface
        .uart_axi(uart_axi.slave),

        //simpleuart interface
        .ser_tx(ser_tx),
        .ser_rx(ser_rx),

        .reg_div_we(reg_div_we),
        .reg_div_di(reg_div_di),
        .reg_div_do(reg_div_do),

        .reg_dat_we(reg_dat_we),
        .reg_dat_re(reg_dat_re),
        .reg_dat_di(reg_dat_di),
        .reg_dat_do(reg_dat_do),
        .reg_dat_wait(reg_dat_wait)
    );

    //simpleuart module used in picorv32 repo
    simpleuart uart (
        .clk        (clk),
        .resetn     (resetn),

        .ser_tx(ser_tx),
        .ser_rx(ser_rx),

        .reg_div_we(reg_div_we),
        .reg_div_di(reg_div_di),
        .reg_div_do(reg_div_do),

        .reg_dat_we(reg_dat_we),
        .reg_dat_re(reg_dat_re),
        .reg_dat_di(reg_dat_di),
        .reg_dat_do(reg_dat_do),
        .reg_dat_wait(reg_dat_wait)
    );

endmodule
