interface axi_interf;
    // AXI4-lite master memory interface

	logic        awvalid;
	logic        awready;
	logic [31:0] awaddr;
	logic [ 2:0] awprot;

	logic        wvalid;
	logic        wready;
	logic [31:0] wdata;
	logic [ 3:0] wstrb;

	logic        bvalid;
	logic        bready;

	logic        arvalid;
	logic        arready;
	logic [31:0] araddr;
	logic [ 2:0] arprot;

	logic        rvalid;
	logic        rready;
	logic [31:0] rdata;

    modport master (
        // AXI4-lite master memory interface

        output  awvalid,
        input   awready,
        output  awaddr,
        output  awprot,

        output  wvalid,
        input   wready,
        output  wdata,
        output  wstrb,

        input   bvalid,
        output  bready,

        output  arvalid,
        input   arready,
        output  araddr,
        output  arprot,

        input   rvalid,
        output  rready,
        input   rdata
    );

    modport slave (
        // AXI4-lite slave memory interface

        input    awvalid,
        output   awready,
        input    awaddr,
        input    awprot,

        input    wvalid,
        output   wready,
        input    wdata,
        input    wstrb,

        output   bvalid,
        input    bready,

        input    arvalid,
        output   arready,
        input    araddr,
        input    arprot,

        output   rvalid,
        input    rready,
        output   rdata
    );
endinterface //axi_interf