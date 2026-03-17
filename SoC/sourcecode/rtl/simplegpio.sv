module simplegpio #(
    parameter GPIO_WIDTH = 32
) (
    input logic clk, resetn,

    axi_interf gpio_axi,

    input  logic [GPIO_WIDTH-1:0] gpio_in,   // physical pin inputs
    output logic [GPIO_WIDTH-1:0] gpio_out,  // physical pin outputs
    output logic [GPIO_WIDTH-1:0] gpio_oe    // output enable (1 = output, 0 = input)
);

    reg [GPIO_WIDTH-1:0] data_reg; // output values
    reg [GPIO_WIDTH-1:0] dir_reg;  // direction: 1 = output, 0 = input

    // drive physical pins
    assign gpio_out = data_reg;
    assign gpio_oe  = dir_reg;

    // AXI handshake: always ready
    assign gpio_axi.awready = 1;
    assign gpio_axi.arready = 1;
    assign gpio_axi.wready  = 1;

    // AXI response registers
    reg        ack_rvalid;
    reg [31:0] ack_rdata;
    reg        ack_bvalid;

    assign gpio_axi.rvalid = ack_rvalid;
    assign gpio_axi.rdata  = ack_rdata;
    assign gpio_axi.bvalid = ack_bvalid;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            data_reg   <= 0;
            dir_reg    <= 0; // all pins input by default
            ack_rvalid <= 0;
            ack_rdata  <= 0;
            ack_bvalid <= 0;
        end else begin

            // clear responses once master consumed them
            if (gpio_axi.rvalid && gpio_axi.rready) ack_rvalid <= 0;
            if (gpio_axi.bvalid && gpio_axi.bready) ack_bvalid <= 0;

            // -------------------------
            // WRITE
            // -------------------------
            if (gpio_axi.awvalid && gpio_axi.wvalid) begin
                case (gpio_axi.awaddr)

                    GPIO_ORIGIN: begin // DATA register
                        if (gpio_axi.wstrb[0]) data_reg[ 7: 0] <= gpio_axi.wdata[ 7: 0];
                        if (gpio_axi.wstrb[1]) data_reg[15: 8] <= gpio_axi.wdata[15: 8];
                        if (gpio_axi.wstrb[2]) data_reg[23:16] <= gpio_axi.wdata[23:16];
                        if (gpio_axi.wstrb[3]) data_reg[31:24] <= gpio_axi.wdata[31:24];
                        ack_bvalid <= 1;
                    end

                    GPIO_ORIGIN + 4: begin // DIR register
                        if (gpio_axi.wstrb[0]) dir_reg[ 7: 0] <= gpio_axi.wdata[ 7: 0];
                        if (gpio_axi.wstrb[1]) dir_reg[15: 8] <= gpio_axi.wdata[15: 8];
                        if (gpio_axi.wstrb[2]) dir_reg[23:16] <= gpio_axi.wdata[23:16];
                        if (gpio_axi.wstrb[3]) dir_reg[31:24] <= gpio_axi.wdata[31:24];
                        ack_bvalid <= 1;
                    end

                endcase
            end

            // -------------------------
            // READ
            // -------------------------
            if (gpio_axi.arvalid) begin
                case (gpio_axi.araddr)

                    GPIO_ORIGIN: begin // DATA register
                        // return pin state: input pins read from gpio_in, output pins read from data_reg
                        ack_rdata  <= (gpio_in & ~dir_reg) | (data_reg & dir_reg);
                        ack_rvalid <= 1;
                    end

                    GPIO_ORIGIN + 4: begin // DIR register
                        ack_rdata  <= dir_reg;
                        ack_rvalid <= 1;
                    end

                endcase
            end

        end
    end

endmodule