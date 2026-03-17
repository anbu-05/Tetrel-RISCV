// controller for simpleuart, an AXI4-lite slave that connects to the simpleuart module

module simpleuart_controller #() (
    input logic clk, resetn,

    // AXI4-lite slave
    axi_interf uart_axi,

    // simpleuart interface
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

    // -- AXI handshake: always ready
    assign uart_axi.awready = 1;
    assign uart_axi.arready = 1;
    assign uart_axi.wready  = 1;

    // -- ack registers for AXI read/write responses
    reg        ack_rvalid;
    reg [31:0] ack_rdata;
    reg        ack_bvalid;

    assign uart_axi.rvalid = ack_rvalid;
    assign uart_axi.rdata  = ack_rdata;
    assign uart_axi.bvalid = ack_bvalid;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            reg_dat_we  <= 0;
            reg_dat_re  <= 0;
            reg_dat_di  <= 0;
            reg_div_we  <= 0;
            reg_div_di  <= 0;
            ack_rvalid  <= 0;
            ack_rdata   <= 0;
            ack_bvalid  <= 0;
        end else begin

            // -- clear all pulses every cycle by default
            reg_dat_we <= 0;
            reg_dat_re <= 0;
            reg_div_we <= 0;

            // -- clear AXI responses once master has consumed them
            if (uart_axi.rvalid && uart_axi.rready) ack_rvalid <= 0;
            if (uart_axi.bvalid && uart_axi.bready) ack_bvalid <= 0;

            // -------------------------
            // WRITE channels
            // -------------------------

            if (uart_axi.awvalid && uart_axi.wvalid) begin
                case (uart_axi.awaddr)

                    UART_ORIGIN + 4: begin // baud divider register
                        reg_div_we <= 4'b1111;
                        reg_div_di <= uart_axi.wdata;
                        ack_bvalid <= 1;
                    end

                    UART_ORIGIN + 8: begin // TX data register
                        if (!reg_dat_wait) begin
                            reg_dat_we <= 1;
                            reg_dat_di <= uart_axi.wdata;
                        end
                        ack_bvalid <= 1;
                    end

                endcase
            end

            // -------------------------
            // READ channels
            // -------------------------

            if (uart_axi.arvalid) begin
                case (uart_axi.araddr)

                    UART_ORIGIN + 0: begin // flags register: bit 0 = TX ready
                        ack_rdata  <= {31'b0, !reg_dat_wait};
                        ack_rvalid <= 1;
                    end

                    UART_ORIGIN + 4: begin // baud divider register
                        ack_rdata  <= reg_div_do;
                        ack_rvalid <= 1;
                    end

                    UART_ORIGIN + 8: begin // RX data register
                        reg_dat_re <= 1;
                        ack_rdata  <= reg_dat_do;
                        ack_rvalid <= 1;
                    end

                endcase
            end

        end
    end

endmodule