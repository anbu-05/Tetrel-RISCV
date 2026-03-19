/* 
i built this memory module based on this article: 
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
endmodule
*/

module handshake (
    input logic clk, resetn,

    input logic [31:0] UPSD, 
    input logic UPSV, DNSR,

    output logic [31:0] DNSD, 
    output logic DNSV, UPSR
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
    always_ff @(posedge clk) begin : handshake_logic
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


module simplemem #(
    parameter MEM_WORDS = 131072, //128KiB (MEM_WORDS * 4 bytes) (till address 0x00020000)
    parameter string PROGRAM_HEX = "../firmware/hex/smoke_test.hex"
) (
    input logic clk, resetn,

    axi_interf mem_axi
);

    reg [31:0] memory [0:(MEM_WORDS/4)-1];

    // AR: receiver
    // R: sender
    // AW: receiver
    // W: receiver
    // B: sender 

    reg [31:0] araddr_buffer;
    reg [31:0] awaddr_buffer;
    reg [31:0] wdata_buffer;

    handshake r_handshake (
        .clk(clk), .resetn(resetn),

        .UPSD(memory[araddr_buffer >> 2]), //input
        .UPSV(ar_handshake.DNSV), //input //did the AR channel receive a valid address? (this prevents reading from memory[0] at reset)
        .UPSR(), //output used in r_handshake

        .DNSD(mem_axi.rdata), //output
        .DNSV(mem_axi.rvalid), //output
        .DNSR(mem_axi.rready) //input
    );

    handshake ar_handshake (
        .clk(clk), .resetn(resetn),

        .UPSD(mem_axi.araddr), //input
        .UPSV(mem_axi.arvalid), //input
        .UPSR(mem_axi.arready), //output

        .DNSD(araddr_buffer), //output //store it in a buffer register
        .DNSV(), //output used in ar_handshake
        .DNSR(r_handshake.UPSR) //input //araddr_buffer availability: did the R channel finish presenting data (checking this saves us from back to back writes messing up read data)
    );

    wire write_ready; // internal signal to indicate both AW and W channels have valid data
    assign write_ready = aw_handshake.DNSV && w_handshake.DNSV; // is the write ready to fire 1.e., are the write addresses and data valid?

    always_ff @(posedge clk) begin : write_logic
        if (write_ready) begin
            if (mem_axi.wstrb[0]) memory[awaddr_buffer >> 2][ 7: 0] <= wdata_buffer[ 7: 0];
            if (mem_axi.wstrb[1]) memory[awaddr_buffer >> 2][15: 8] <= wdata_buffer[15: 8];
            if (mem_axi.wstrb[2]) memory[awaddr_buffer >> 2][23:16] <= wdata_buffer[23:16];
            if (mem_axi.wstrb[3]) memory[awaddr_buffer >> 2][31:24] <= wdata_buffer[31:24];
        end
    end

    handshake aw_handshake (
        .clk(clk), .resetn(resetn),

        .UPSD(mem_axi.awaddr), //input
        .UPSV(mem_axi.awvalid), //input
        .UPSR(mem_axi.awready), //output

        .DNSD(awaddr_buffer), //output
        .DNSV(), //output //used in writing to memory (write_ready)
        .DNSR(write_ready) //input //awaddr_buffer availability
    );

    handshake w_handshake (
        .clk(clk), .resetn(resetn),

        .UPSD(mem_axi.wdata), //input
        .UPSV(mem_axi.wvalid), //input
        .UPSR(mem_axi.wready), //output

        .DNSD(wdata_buffer), //output
        .DNSV(), //output //used in writing to memory (write_ready)
        .DNSR(write_ready) //input //wdata_buffer availability
    );

    handshake b_handshake (
        .clk(clk), .resetn(resetn),

        .UPSD(32'b0), //input //the write is always OKAY
        .UPSV(write_ready), //input //the write is complete
        .UPSR(), //output //not used, since we're not reporting to the master about the status of the write, and picorv32 doesnt require this either

        .DNSD(mem_axi.bresp), //output
        .DNSV(mem_axi.bvalid), //output
        .DNSR(mem_axi.bready) //input
    );

//----------------------------------------------------------------------------

    // if ROM_ORIGIN is non-zero, load hex starting at that offset in the array
    initial begin
        $readmemh(PROGRAM_HEX, memory);
    end
    
endmodule