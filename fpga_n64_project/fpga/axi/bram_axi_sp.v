//RESEN

`timescale 1ns / 1ps

module bram_axi_sp #(
    parameter ADDR_WIDTH = 12,       // 4096 words -> 16 KB
    parameter DATA_WIDTH = 32
)(
    input                  mem_axi_aclk,
    input                  mem_axi_aresetn,

    // Write address / data channel
    input      [ADDR_WIDTH+1:0] mem_axi_awaddr,
    input                  mem_axi_awvalid,
    output reg             mem_axi_awready,
    input      [DATA_WIDTH-1:0] mem_axi_wdata,
    input                  mem_axi_wvalid,
    output reg             mem_axi_wready,
    output reg [1:0]       mem_axi_bresp,
    output reg             mem_axi_bvalid,
    input                  mem_axi_bready,

    // Read address / data channel
    input      [ADDR_WIDTH+1:0] mem_axi_araddr,
    input                  mem_axi_arvalid,
    output reg             mem_axi_arready,
    output reg [DATA_WIDTH-1:0] mem_axi_rdata,
    output reg [1:0]       mem_axi_rresp,
    output reg             mem_axi_rvalid,
    input                  mem_axi_rready
);

    // Internal address wires
    wire [ADDR_WIDTH-1:0] waddr = mem_axi_awaddr[ADDR_WIDTH+1:2];
    wire [ADDR_WIDTH-1:0] raddr = mem_axi_araddr[ADDR_WIDTH+1:2];

    // -------------------------------------------------------------------------
    // Instantiate the M9K block RAM using altsyncram
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] bram [0:(1<<ADDR_WIDTH)-1];
    (* ramstyle = "M9K" *) wire [DATA_WIDTH-1:0] bram_data;

    // Simple synchronous read/write process
    always @(posedge mem_axi_aclk) begin
        if (!mem_axi_aresetn) begin
            mem_axi_awready <= 0;
            mem_axi_wready  <= 0;
            mem_axi_bvalid  <= 0;
            mem_axi_bresp   <= 2'b11;
            mem_axi_rresp   <= 2'b11;
            mem_axi_arready <= 0;
            mem_axi_rvalid  <= 0;
            mem_axi_rdata   <= 0;
            // Optionally clear BRAM outputs, not the memory
        end else begin
            // Write address handshake
            mem_axi_awready <= !mem_axi_awready && mem_axi_awvalid;
            mem_axi_wready  <= !mem_axi_wready && mem_axi_wvalid;

            // Write operation
            if (mem_axi_awvalid && mem_axi_wvalid) begin
                bram[waddr] <= mem_axi_wdata;
                mem_axi_bvalid <= 1'b1;
                mem_axi_bresp  <= 2'b00; // OKAY
            end
            if (mem_axi_bvalid && mem_axi_bready) begin
                mem_axi_bvalid <= 1'b0;
            end

            // Read address handshake
            mem_axi_arready <= !mem_axi_arready && mem_axi_arvalid;

            // Read operation
            if (mem_axi_arvalid) begin
                mem_axi_rdata  <= bram[raddr];
                mem_axi_rvalid <= 1'b1;
                mem_axi_rresp  <= 2'b00; // OKAY
            end
            if (mem_axi_rvalid && mem_axi_rready) begin
                mem_axi_rvalid <= 1'b0;
                mem_axi_rdata  <= 32'd0;
            end
        end
    end

endmodule
