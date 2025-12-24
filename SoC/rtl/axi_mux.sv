module axi_mux # (
    parameter ROM_ORIGIN = 32'h00000000,
    parameter ROM_LENGTH = 32'h00010000, // 64 KiB
    parameter RAM_ORIGIN = 32'h00010000,
    parameter RAM_LENGTH = 32'h00008000, // 32 KiB
    parameter SLAVE1_REG_ORIGIN = 32'h00018000,
    parameter SLAVE1_REG_LENGTH = 32'h0000000c
)(
    axi_interf.master master_axi,
    axi_interf.slave  slave0_axi,
    axi_interf.slave  slave1_axi
);

    // small helpers
    localparam logic [31:0] ROM_HIGH = ROM_ORIGIN        + ROM_LENGTH;
    localparam logic [31:0] RAM_HIGH = RAM_ORIGIN        + RAM_LENGTH;
    localparam logic [31:0] S1_HIGH  = SLAVE1_REG_ORIGIN + SLAVE1_REG_LENGTH;

    function logic in_rom(input logic [31:0] a); return (a >= ROM_ORIGIN) && (a < ROM_HIGH); endfunction
    function logic in_ram(input logic [31:0] a); return (a >= RAM_ORIGIN) && (a < RAM_HIGH); endfunction
    function logic in_s1(input logic [31:0] a);  return (a >= SLAVE1_REG_ORIGIN) && (a < S1_HIGH); endfunction

    // ---------- macros (correct directions) ----------
    `define CONNECT_AR_M_TO_S(m,s) \
        s.arvalid = m.arvalid; \
        s.araddr  = m.araddr;  \
        s.arprot  = m.arprot;  \
        m.arready = s.arready;

    `define CONNECT_R_S_TO_M(m,s)  \
        m.rvalid  = s.rvalid;  \
        m.rdata   = s.rdata;   \
        s.rready  = m.rready;

    `define CONNECT_AW_M_TO_S(m,s) \
        s.awvalid = m.awvalid; \
        s.awaddr  = m.awaddr;  \
        s.awprot  = m.awprot;  \
        m.awready = s.awready;

    `define CONNECT_W_M_TO_S(m,s) \
        s.wvalid  = m.wvalid;  \
        s.wdata   = m.wdata;   \
        s.wstrb   = m.wstrb;   \
        m.wready  = s.wready;

    `define CONNECT_B_S_TO_M(m,s) \
        m.bvalid  = s.bvalid;  \
        s.bready  = m.bready;

    // ---------- combinational routing ----------
    // Provide full defaults first (avoid latches)
    always_comb begin
        // default: slave0/1 signals not driven
        slave0_axi.awvalid = 1'b0; slave0_axi.awaddr = 32'h0; slave0_axi.awprot = 3'h0;
        slave1_axi.awvalid = 1'b0; slave1_axi.awaddr = 32'h0; slave1_axi.awprot = 3'h0;

        slave0_axi.wvalid  = 1'b0; slave0_axi.wdata  = 32'h0; slave0_axi.wstrb  = 4'h0;
        slave1_axi.wvalid  = 1'b0; slave1_axi.wdata  = 32'h0; slave1_axi.wstrb  = 4'h0;

        slave0_axi.arvalid = 1'b0; slave0_axi.araddr = 32'h0; slave0_axi.arprot = 3'h0;
        slave1_axi.arvalid = 1'b0; slave1_axi.araddr = 32'h0; slave1_axi.arprot = 3'h0;

        slave0_axi.bready  = 1'b0;
        slave1_axi.bready  = 1'b0;

        slave0_axi.rready  = 1'b0;
        slave1_axi.rready  = 1'b0;

        // master defaults (responses/ready)
        master_axi.awready = 1'b0;
        master_axi.wready  = 1'b0;
        master_axi.bvalid  = 1'b0;

        master_axi.arready = 1'b0;
        master_axi.rvalid  = 1'b0;
        master_axi.rdata   = 32'h0;

        // ---------- AR channel ----------
        if (master_axi.arvalid) begin
            if (in_s1(master_axi.araddr)) begin
                `CONNECT_AR_M_TO_S(master_axi, slave1_axi)
            end else begin
                // ROM or RAM -> slave0
                `CONNECT_AR_M_TO_S(master_axi, slave0_axi)
            end
        end else begin
            // nothing to route (defaults already set)
        end

        // ---------- AW channel ----------
        if (master_axi.awvalid) begin
            if (in_s1(master_axi.awaddr)) begin
                `CONNECT_AW_M_TO_S(master_axi, slave1_axi)
            end else begin
                `CONNECT_AW_M_TO_S(master_axi, slave0_axi)
            end
        end

        // ---------- W channel ----------
        // combinationally route write data based on AW address if W is valid
        
        if (master_axi.wvalid) begin
            if (in_s1(master_axi.awaddr)) begin
                `CONNECT_W_M_TO_S(master_axi, slave1_axi)
            end else begin
                `CONNECT_W_M_TO_S(master_axi, slave0_axi)
            end
        end

        // ---------- B channel (write response) ----------
        // Route response back from slave chosen by AW addr; default slave0
        if (in_s1(master_axi.awaddr)) begin
            `CONNECT_B_S_TO_M(master_axi, slave1_axi)
        end else begin
            `CONNECT_B_S_TO_M(master_axi, slave0_axi)
        end

        // ---------- R channel (read response) ----------
        // Route read response back from slave chosen by AR addr; default slave0
        if (in_s1(master_axi.araddr)) begin
            `CONNECT_R_S_TO_M(master_axi, slave1_axi)
        end else begin
            `CONNECT_R_S_TO_M(master_axi, slave0_axi)
        end
    end

endmodule
