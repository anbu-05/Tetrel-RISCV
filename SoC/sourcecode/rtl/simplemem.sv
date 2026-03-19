/* i built this memory module based on this article: 
https://www.itdev.co.uk/blog/pipelining-axi-buses-registered-ready-signals

and a basic generated d_ff (with enable) design:

module d_ff_en (
    input logic clk, resetn, en,
    input logic d,
    output logic q
);
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn)
            q <= 0;
        else if (en)
            q <= d;
    end

*/


module simplemem #(
    parameter MEM_WORDS = 131072, //128KiB (MEM_WORDS * 4 bytes) (till address 0x00020000)
    parameter string PROGRAM_HEX = "../firmware/hex/smoke_test.hex"
) (
    input logic clk, resetn,

    axi_interf mem,

    input  logic 		mem_valid, //
    input  logic 		mem_instr,
    output logic 		mem_ready, //
    input  logic [31:0] mem_addr, //
    input  logic [31:0] mem_wdata, //
    input  logic [ 3:0] mem_wstrb,
    output logic [31:0] mem_rdata //
);

    reg [31:0] memory [0:(MEM_WORDS/4)-1];

    // AR: receiver
    // R: sender
    // AW: receiver
    // W: receiver
    // B: sender 

    reg [31:0] araddr_buffer;
    reg [31:0] awaddr_buffer;

    handshake r_handshake (
        .clk(clk), .resetn(resetn),

        .UPSD(memory[araddr_buffer >> 2]), 
        .UPSV(), 
        .DNSR(),

        .DNSD(mem.rdata), 
        .DNSV(mem.rvalid), 
        .UPSR(mem.rready)
    );

    handshake ar_handshake (
        .clk(clk), .resetn(resetn),

        .UPSD(mem.araddr), 
        .UPSV(mem.arvalid), 
        .DNSR(mem.arready),

        .DNSD(araddr_buffer), 
        .DNSV(), 
        .UPSR()
    );

    handshake aw_handshake (
        .clk(clk), .resetn(resetn),

        .UPSD(), 
        .UPSV(), 
        .DNSR(),

        .DNSD(), 
        .DNSV(), 
        .UPSR()
    );

    handshake w_handshake (
        .clk(clk), .resetn(resetn),

        .UPSD(), 
        .UPSV(), 
        .DNSR(),

        .DNSD(), 
        .DNSV(), 
        .UPSR()
    );

    handshake b_handshake (
        .clk(clk), .resetn(resetn),

        .UPSD(), 
        .UPSV(), 
        .DNSR(),

        .DNSD(), 
        .DNSV(), 
        .UPSR()
    );


//----------------------------------------------------------------------------

    // if ROM_ORIGIN is non-zero, load hex starting at that offset in the array
    initial begin
        $readmemh(PROGRAM_HEX, memory);
    end
    
endmodule

module handshake (
    input logic clk, resetn,
    input logic UPSD, UPSV, DNSR,
    output logic DNSD, DNSV, UPSR
);

    /*
    D (data) = UPSD
    Q (data) = DNSD

    D (valid) = UPSV
    Q (valid) = DNSV

    en = UPSR = !Q (valid) || DNSR
    */

    reg ack;
    assign ack = DNSV;
    assign UPSR = !ack || DNSR; // en
    always_ff @(posedge clk or posedge resetn) begin
        if (!resetn) begin
            DNSD <= 0; // Q (data) <= 0
            DNSV <= 0; // Q (valid) <= 0
        end else begin 
            if (UPSR) begin // if en
                DNSD <= UPSD; // Q (data) <= D (data)
                DNSV <= UPSV; // Q (valid) <= D (valid)
            end
        end
    end
endmodule