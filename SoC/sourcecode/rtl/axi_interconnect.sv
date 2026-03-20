// does the muxing of multiple slaves on the AXI bus; i.e. implements the address decoding and routing logic for the interconnect
// take care of memory mapping for each slave by subtracting the base address so each slave sees a contiguous address space starting at 0

module axi_interconnect # (
    parameter SLAVE0_ORIGIN = 32'h00000000,
    parameter SLAVE0_LENGTH = 32'h00020000,
    parameter SLAVE1_ORIGIN = 32'hFFFF1000,
    parameter SLAVE1_LENGTH = 32'h0000000c,
    parameter SLAVE2_ORIGIN = 32'hFFFF2000,
    parameter SLAVE2_LENGTH = 32'h00000008
)(
    axi_interf master_axi,
    axi_interf slave0_axi,
    axi_interf slave1_axi,
    axi_interf slave2_axi
);

    localparam logic [31:0] S0_HIGH = SLAVE0_ORIGIN + SLAVE0_LENGTH;
    localparam logic [31:0] S1_HIGH = SLAVE1_ORIGIN + SLAVE1_LENGTH;
    localparam logic [31:0] S2_HIGH = SLAVE2_ORIGIN + SLAVE2_LENGTH;

    function logic in_s0(input logic [31:0] a); return (a >= SLAVE0_ORIGIN) && (a < S0_HIGH); endfunction
    function logic in_s1(input logic [31:0] a); return (a >= SLAVE1_ORIGIN) && (a < S1_HIGH); endfunction
    function logic in_s2(input logic [31:0] a); return (a >= SLAVE2_ORIGIN) && (a < S2_HIGH); endfunction

    // ---------- macros ----------
    // AR channel: forward address with base subtracted so slave sees offset from 0
    `define CONNECT_AR_M_TO_S(m, s, base) \
        s.arvalid = m.arvalid; \
        s.araddr  = m.araddr - base; \
        s.arprot  = m.arprot; \
        m.arready = s.arready;

    `define CONNECT_R_S_TO_M(m, s) \
        m.rvalid = s.rvalid; \
        m.rdata  = s.rdata;  \
        s.rready = m.rready;

    // AW channel: forward address with base subtracted so slave sees offset from 0
    `define CONNECT_AW_M_TO_S(m, s, base) \
        s.awvalid = m.awvalid; \
        s.awaddr  = m.awaddr - base; \
        s.awprot  = m.awprot; \
        m.awready = s.awready;

    `define CONNECT_W_M_TO_S(m, s) \
        s.wvalid = m.wvalid; \
        s.wdata  = m.wdata;  \
        s.wstrb  = m.wstrb;  \
        m.wready = s.wready;

    `define CONNECT_B_S_TO_M(m, s) \
        m.bvalid = s.bvalid; \
        s.bready = m.bready;

    // ---------- combinational routing ----------
    always_comb begin
        // defaults: deassert all slave inputs
        slave0_axi.awvalid = 1'b0; slave0_axi.awaddr = 32'h0; slave0_axi.awprot = 3'h0;
        slave1_axi.awvalid = 1'b0; slave1_axi.awaddr = 32'h0; slave1_axi.awprot = 3'h0;
        slave2_axi.awvalid = 1'b0; slave2_axi.awaddr = 32'h0; slave2_axi.awprot = 3'h0;

        slave0_axi.wvalid  = 1'b0; slave0_axi.wdata  = 32'h0; slave0_axi.wstrb  = 4'h0;
        slave1_axi.wvalid  = 1'b0; slave1_axi.wdata  = 32'h0; slave1_axi.wstrb  = 4'h0;
        slave2_axi.wvalid  = 1'b0; slave2_axi.wdata  = 32'h0; slave2_axi.wstrb  = 4'h0;

        slave0_axi.arvalid = 1'b0; slave0_axi.araddr = 32'h0; slave0_axi.arprot = 3'h0;
        slave1_axi.arvalid = 1'b0; slave1_axi.araddr = 32'h0; slave1_axi.arprot = 3'h0;
        slave2_axi.arvalid = 1'b0; slave2_axi.araddr = 32'h0; slave2_axi.arprot = 3'h0;

        slave0_axi.bready  = 1'b0;
        slave1_axi.bready  = 1'b0;
        slave2_axi.bready  = 1'b0;

        slave0_axi.rready  = 1'b0;
        slave1_axi.rready  = 1'b0;
        slave2_axi.rready  = 1'b0;

        master_axi.awready = 1'b0;
        master_axi.wready  = 1'b0;
        master_axi.bvalid  = 1'b0;
        master_axi.arready = 1'b0;
        master_axi.rvalid  = 1'b0;
        master_axi.rdata   = 32'h0;

        // ---------- AR channel ----------
        if (master_axi.arvalid) begin
            if (in_s1(master_axi.araddr)) begin
                `CONNECT_AR_M_TO_S(master_axi, slave1_axi, SLAVE1_ORIGIN)
            end else if (in_s2(master_axi.araddr)) begin
                `CONNECT_AR_M_TO_S(master_axi, slave2_axi, SLAVE2_ORIGIN)
            end else begin
                `CONNECT_AR_M_TO_S(master_axi, slave0_axi, SLAVE0_ORIGIN)
            end
        end

        // ---------- AW channel ----------
        if (master_axi.awvalid) begin
            if (in_s1(master_axi.awaddr)) begin
                `CONNECT_AW_M_TO_S(master_axi, slave1_axi, SLAVE1_ORIGIN)
            end else if (in_s2(master_axi.awaddr)) begin
                `CONNECT_AW_M_TO_S(master_axi, slave2_axi, SLAVE2_ORIGIN)
            end else begin
                `CONNECT_AW_M_TO_S(master_axi, slave0_axi, SLAVE0_ORIGIN)
            end
        end

        // ---------- W channel ----------
        if (master_axi.wvalid) begin
            if (in_s1(master_axi.awaddr)) begin
                `CONNECT_W_M_TO_S(master_axi, slave1_axi)
            end else if (in_s2(master_axi.awaddr)) begin
                `CONNECT_W_M_TO_S(master_axi, slave2_axi)
            end else begin
                `CONNECT_W_M_TO_S(master_axi, slave0_axi)
            end
        end

        // ---------- B channel ----------
        if (in_s1(master_axi.awaddr)) begin
            `CONNECT_B_S_TO_M(master_axi, slave1_axi)
        end else if (in_s2(master_axi.awaddr)) begin
            `CONNECT_B_S_TO_M(master_axi, slave2_axi)
        end else begin
            `CONNECT_B_S_TO_M(master_axi, slave0_axi)
        end

        // ---------- R channel ----------
        if (in_s1(master_axi.araddr)) begin
            `CONNECT_R_S_TO_M(master_axi, slave1_axi)
        end else if (in_s2(master_axi.araddr)) begin
            `CONNECT_R_S_TO_M(master_axi, slave2_axi)
        end else begin
            `CONNECT_R_S_TO_M(master_axi, slave0_axi)
        end
    end

endmodule