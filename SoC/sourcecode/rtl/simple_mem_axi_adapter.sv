module simple_mem_axi_adapter #(
    //
) (
    input logic clk, resetn,

    // AXI4-lite slave memory interface

    axi_interf mem_axi,

    // Native PicoRV32 memory interface (for slave)

	output logic        mem_valid, //
	output logic        mem_instr,
	input  logic        mem_ready, //
	output logic [31:0] mem_addr, //
	output logic [31:0] mem_wdata, //
	output logic [ 3:0] mem_wstrb, //
	input  logic [31:0] mem_rdata //

);

    logic [31:0] read_addr;
    logic [31:0] write_addr;
    wire [31:0] read_data;
    logic [31:0] write_data;

//-------------------------------
//---------read channels---------

    logic read_pending_set;
    logic read_pending_clr;
    logic read_pending;

    always_ff @( posedge clk or negedge resetn ) begin : read_pending_state
        if (!resetn) begin 
            read_pending <= 0;
        end else read_pending <= read_pending_set || (read_pending && !read_pending_clr);
    end

        //---------AR channel---------
    always_ff @( posedge clk or negedge resetn ) begin : AR
        if (!resetn) begin
            read_addr <= 0;
            read_pending_set <= 0;
            // mem_axi.arready <= 0;
        end else begin
            // mem_axi.arready <= !read_pending; //can be driven by slave device also
            if (mem_axi.arready && mem_axi.arvalid) begin
                read_addr <= mem_axi.araddr;
                read_pending_set <= 1;
            end else read_pending_set <= 0;
        end
    end

        //---------R channel---------
    always_ff @( posedge clk or negedge resetn ) begin : R
        if (!resetn) begin
            mem_axi.rvalid <= 0;
            read_pending_clr <= 0;
            mem_axi.rdata <= 0;
        end else begin
            mem_axi.rvalid <= read_pending; //can be driven by slave device also
            if (mem_axi.rvalid) begin 
                mem_axi.rdata <= read_data;
                if (mem_axi.rready) read_pending_clr <= 1;
                else read_pending_clr <= 0;
            end else read_pending_clr <= 0;
        end
    end



//--------------------------------
//---------write channels---------

    logic aw_complete_set;
    logic aw_complete_clr;
    logic aw_complete;

    always_ff @( posedge clk or negedge resetn ) begin : aw_complete_state
        if (!resetn) begin 
            aw_complete <= 0;
        end else aw_complete <= aw_complete_set || (aw_complete && !aw_complete_clr);
    end

    logic w_complete_set;
    logic w_complete_clr;
    logic w_complete;

    always_ff @( posedge clk or negedge resetn ) begin : w_complete_state
        if (!resetn) begin 
            w_complete <= 0;
        end else w_complete <= w_complete_set || (w_complete && !w_complete_clr);
    end

        //---------AW channel---------
    always_ff @( posedge clk or negedge resetn ) begin : AW
        if (!resetn) begin
            write_addr <= 0;
            // mem_axi.awready <= 0;
            aw_complete_set <= 0;
        end else begin
            // mem_axi.awready <= !aw_complete && mem_ready; //can be driven by slave device also 
            if (mem_axi.awready && mem_axi.awvalid) begin
                write_addr <= mem_axi.awaddr;
                aw_complete_set <= 1;
            end else aw_complete_set <= 0;
        end
    end

        //---------W channel---------
    always_ff @( posedge clk or negedge resetn ) begin : W
        if (!resetn) begin
            write_data <= 0;
            mem_axi.wready <= 0;
            w_complete_set <= 0;
        end else begin
            mem_axi.wready <= !w_complete && mem_axi.awready; //can be driven by slave device also 
            if (mem_axi.wready && mem_axi.wvalid) begin
                write_data <= mem_axi.wdata;
                /*
                note: uncomment the above line and comment the below lines, 
                and connect mem_axi.wstrb 
                if you want the slave to take care of write strobing, 
                instead of the adapter.
                */
                // if (mem_axi.wstrb[0]) write_data[ 7: 0] <= mem_axi.wdata[ 7: 0];
                // if (mem_axi.wstrb[1]) write_data[15: 8] <= mem_axi.wdata[15: 8];
                // if (mem_axi.wstrb[2]) write_data[23:16] <= mem_axi.wdata[23:16];
                // if (mem_axi.wstrb[3]) write_data[31:24] <= mem_axi.wdata[31:24];
                w_complete_set <= 1;
            end else w_complete_set <= 0;
        end
    end

//---------memory control---------
        //---------ready signals---------
    assign mem_valid = (read_pending) ? mem_axi.arvalid : mem_axi.awvalid; //can be driven by slave device also
    always_comb begin : mem_ready_mgmt
        if (read_pending) mem_axi.arready <= mem_ready;
        else mem_axi.awready <= !aw_complete && mem_ready;
    end
        //---------read---------
    assign read_data = mem_rdata;
        //---------write---------
    assign mem_wdata = write_data;
        //---------address management---------
    always_comb begin : mem_addr_mgmt
        if (mem_valid && mem_axi.wstrb) begin 
            mem_addr <= write_addr;
            mem_wstrb <= mem_axi.wstrb;
        end else mem_addr <= read_addr;
    end

    //note: for use in other kinds of slaves

    // //---------memory dump---------
    // always_ff @( posedge clk or negedge resetn ) begin : mem_dump
    //     if (!resetn) begin
    //         aw_complete_clr <= 0;
    //         w_complete_clr <= 0;
    //     end else begin
    //         if (aw_complete && w_complete) begin
    //             memory[write_addr] <= write_data;
    //             aw_complete_clr <= 1;
    //             w_complete_clr <= 1;
    //         end else begin
    //             aw_complete_clr <= 0;
    //             w_complete_clr <= 0;
    //         end
    //     end
    // end

endmodule