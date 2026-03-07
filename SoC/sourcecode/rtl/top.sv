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
    axi_interf picorv32_axi();
    axi_interf mem_axi();
    axi_interf uart_axi();
    axi_interf gpio_axi();
    axi_interf imc_axi();

//---------instantiations---------
    // PicoRV32 core
    picorv32 #(
        .ENABLE_MUL(1)
    ) core (
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
        .mem_axi_awvalid (picorv32_axi.awvalid),
        .mem_axi_awready (picorv32_axi.awready),
        .mem_axi_awaddr  (picorv32_axi.awaddr),
        .mem_axi_awprot  (picorv32_axi.awprot),
            //Write Data Channel
        .mem_axi_wvalid  (picorv32_axi.wvalid),
        .mem_axi_wready  (picorv32_axi.wready),
        .mem_axi_wdata   (picorv32_axi.wdata),
        .mem_axi_wstrb   (picorv32_axi.wstrb),
            //Write Response Channel
        .mem_axi_bvalid  (picorv32_axi.bvalid),
        .mem_axi_bready  (picorv32_axi.bready),
            //Read Address Channel
        .mem_axi_arvalid (picorv32_axi.arvalid),
        .mem_axi_arready (picorv32_axi.arready),
        .mem_axi_araddr  (picorv32_axi.araddr),
        .mem_axi_arprot  (picorv32_axi.arprot),
            //Read Data Channel
        .mem_axi_rvalid  (picorv32_axi.rvalid),
        .mem_axi_rready  (picorv32_axi.rready),
        .mem_axi_rdata   (picorv32_axi.rdata)
    );

    // AXI mux to interface with multiple slaves; i.e. axi interconnect
    axi_interconnect #(
        .SLAVE0_ORIGIN(32'h00000000),
        .SLAVE0_LENGTH(32'h00018000), // covers ROM + RAM
        .SLAVE1_ORIGIN(32'h00018000),
        .SLAVE1_LENGTH(32'h0000000c),
        .SLAVE2_ORIGIN(32'h00020000),
        .SLAVE2_LENGTH(32'h00000008)
        .SLAVE3_ORIGIN(32'h00030000),
        .SLAVE3_LENGTH(32'h00000008)
    ) mux (
        .master_axi(picorv32_axi.master),
        .slave0_axi(mem_axi.slave),
        .slave1_axi(uart_axi.slave),
<<<<<<< HEAD
        .slave2_axi(gpio_axi.slave),
=======
        .slave2_axi(gpio_axi.slave)
>>>>>>> d2b2385 (did git rebase and added ashmit's files)
        .slave3_axi(imc_axi.slave)
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
        .PROGRAM_HEX("../firmware/hex/smoke_test.hex")
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

    //uart AXI adapter
    simpleuart_controller controller (
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

    //simplegpio module
    simplegpio gpio (
        .clk      (clk),
        .resetn   (resetn),

        .gpio_axi (gpio_axi.slave),
        
        .gpio_in  (32'b0),    // tie to 0 for now, no physical pins in sim
        .gpio_out (),         // leave unconnected, we don't need it in sim
        .gpio_oe  ()          // leave unconnected
    );

<<<<<<< HEAD
    //ReRAM-IMC

    imc_memory_block imc (
        .clk        (clk),
        .resetn     (resetn),

        // AXI interface
        .imc_axi(imc_axi.slave)
=======
    imc_memory_block imc (
        .clk      (clk),
        .resetn   (resetn),

        .imc_axi  (imc_axi.slave)
>>>>>>> d2b2385 (did git rebase and added ashmit's files)
    );

endmodule
