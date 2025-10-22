//RESEN

module axi_lite_arbiter (

    input  clk,
    input  resetn,
    input  processor_reset,

    // PicoRV32 AXI Interface (Master 1)
    input  [31:0]  pico_axi_awaddr,
    input  [ 2:0]  pico_axi_awprot,
    input          pico_axi_awvalid,
    output         pico_axi_awready,
    
    input  [31:0]  pico_axi_wdata,
    input  [ 3:0]  pico_axi_wstrb,
    input          pico_axi_wvalid,
    output         pico_axi_wready,
    
    output [ 1:0]  pico_axi_bresp,
    output         pico_axi_bvalid,
    input          pico_axi_bready,
    
    input  [31:0]  pico_axi_araddr,
    input  [ 2:0]  pico_axi_arprot,
    input          pico_axi_arvalid,
    output         pico_axi_arready,
    
    output [31:0]  pico_axi_rdata,
    output [ 1:0]  pico_axi_rresp,
    output         pico_axi_rvalid,
    input          pico_axi_rready,
    
    // UART AXI Interface (Master 0)
    input  [31:0]  uart_axi_awaddr,
    input  [ 2:0]  uart_axi_awprot,
    input          uart_axi_awvalid,
    output         uart_axi_awready,
    
    input  [31:0]  uart_axi_wdata,
    input  [ 3:0]  uart_axi_wstrb,
    input          uart_axi_wvalid,
    output         uart_axi_wready,
    
    output [ 1:0]  uart_axi_bresp,
    output         uart_axi_bvalid,
    input          uart_axi_bready,
    
    input  [31:0]  uart_axi_araddr,
    input  [ 2:0]  uart_axi_arprot,
    input          uart_axi_arvalid,
    output         uart_axi_arready,
    
    output [31:0]  uart_axi_rdata,
    output [ 1:0]  uart_axi_rresp,
    output         uart_axi_rvalid,
    input          uart_axi_rready,
    
    // BRAM AXI Interface (Slave 0)
    output [31:0]  bram_axi_awaddr,
    output [ 2:0]  bram_axi_awprot,
    output         bram_axi_awvalid,
    input          bram_axi_awready,
    
    output [31:0]  bram_axi_wdata,
    output [ 3:0]  bram_axi_wstrb,
    output         bram_axi_wvalid,
    input          bram_axi_wready,
    
    input  [ 1:0]  bram_axi_bresp,
    input          bram_axi_bvalid,
    output         bram_axi_bready,
    
    output [31:0]  bram_axi_araddr,
    output [ 2:0]  bram_axi_arprot,
    output         bram_axi_arvalid,
    input          bram_axi_arready,
    
    input  [31:0]  bram_axi_rdata,
    input  [ 1:0]  bram_axi_rresp,
    input          bram_axi_rvalid,
    output         bram_axi_rready,
    
    // SDRAM AXI Interface (Slave 1)
    output [31:0]  sdram_axi_awaddr,
    output [ 2:0]  sdram_axi_awprot,
    output         sdram_axi_awvalid,
    input          sdram_axi_awready,
    
    output [31:0]  sdram_axi_wdata,
    output [ 3:0]  sdram_axi_wstrb,
    output         sdram_axi_wvalid,
    input          sdram_axi_wready,
    
    input  [ 1:0]  sdram_axi_bresp,
    input          sdram_axi_bvalid,
    output         sdram_axi_bready,
    
    output [31:0]  sdram_axi_araddr,
    output [ 2:0]  sdram_axi_arprot,
    output         sdram_axi_arvalid,
    input          sdram_axi_arready,
    
    input  [31:0]  sdram_axi_rdata,
    input  [ 1:0]  sdram_axi_rresp,
    input          sdram_axi_rvalid,
    output         sdram_axi_rready,
    
    // Memory Mapped Registers AXI Interface (Slave 2)
    output [31:0]  led_reg_axi_awaddr,
    //output [ 2:0]  led_reg_axi_awprot,
    output         led_reg_axi_awvalid,
    input          led_reg_axi_awready,
    
    output [31:0]  led_reg_axi_wdata,
    output [ 3:0]  led_reg_axi_wstrb,
    output         led_reg_axi_wvalid,
    input          led_reg_axi_wready,
    
    input  [ 1:0]  led_reg_axi_bresp,
    input          led_reg_axi_bvalid,
    output         led_reg_axi_bready,
    
    output [31:0]  led_reg_axi_araddr,
    //output [ 2:0]  led_reg_axi_arprot,
    output         led_reg_axi_arvalid,
    input          led_reg_axi_arready,
    
    input  [31:0]  led_reg_axi_rdata,
    input  [ 1:0]  led_reg_axi_rresp,
    input          led_reg_axi_rvalid,
    output         led_reg_axi_rready,

    // Memory Mapped Registers AXI Interface (Slave 3)
    output [31:0]  reset_reg_axi_awaddr,
    //output [ 2:0]  reset_reg_axi_awprot,
    output         reset_reg_axi_awvalid,
    input          reset_reg_axi_awready,
    
    output [31:0]  reset_reg_axi_wdata,
    output [ 3:0]  reset_reg_axi_wstrb,
    output         reset_reg_axi_wvalid,
    input          reset_reg_axi_wready,
    
    input  [ 1:0]  reset_reg_axi_bresp,
    input          reset_reg_axi_bvalid,
    output         reset_reg_axi_bready,
    
    output [31:0]  reset_reg_axi_araddr,
    //output [ 2:0]  reset_reg_axi_arprot,
    output         reset_reg_axi_arvalid,
    input          reset_reg_axi_arready,
    
    input  [31:0]  reset_reg_axi_rdata,
    input  [ 1:0]  reset_reg_axi_rresp,
    input          reset_reg_axi_rvalid,
    output         reset_reg_axi_rready
    
);

// Address offset definitions
localparam BRAM_ADDR_OFSET  = 8'h00;
localparam SDRAM_ADDR_OFSET = 8'h20;
localparam LED_ADDR_OFSET   = 8'h40;
localparam RESET_ADDR_OFSET = 8'h41;
localparam ADDR_MASK        = 32'h00ffffff;

// ------------------------------------------------------------------
// Internal arbitration state
// ------------------------------------------------------------------
reg        read_active;
reg        current_read_master;   // 0 = UART, 1 = PICO
reg [7:0]  read_sel_slave;
reg [31:0] read_addr_latched;

reg        write_active;
reg        current_write_master;  // 0 = UART, 1 = PICO
reg [7:0]  write_sel_slave;
reg [31:0] write_addr_latched;

// accept pulses: true when master presented VALID and arbiter granted (i.e. AWREADY/ARREADY sampled)
wire uart_aw_accept = !write_active && uart_axi_awvalid;
wire pico_aw_accept = !write_active && !uart_axi_awvalid && pico_axi_awvalid;

wire uart_ar_accept = !read_active && uart_axi_arvalid;
wire pico_ar_accept = !read_active && !uart_axi_arvalid && pico_axi_arvalid;


// ------------------------------------------------------------------
// Synchronous latching of grants and address capture
// ------------------------------------------------------------------
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        // read side
        read_active         <= 1'b0;
        current_read_master <= 1'b0;
        read_sel_slave      <= 8'h0;
        read_addr_latched   <= 32'h0;

        // write side
        write_active         <= 1'b0;
        current_write_master <= 1'b0;
        write_sel_slave      <= 8'h0;
        write_addr_latched   <= 32'h0;
    end else if (!processor_reset && (current_read_master || current_write_master)) begin
        // CRITICAL FIX: Clear processor-related active transactions when processor is reset
        if (current_read_master == 1'b1) begin
            read_active          <= 1'b0;  // Clear stuck PicoRV32 read transaction
            current_read_master  <= 1'b0;
        end
        if (current_write_master == 1'b1) begin
            write_active         <= 1'b0; // Clear stuck PicoRV32 write transaction
            current_write_master <= 1'b0;
        end 
    end else begin
        // ------------ READ accept -------------
        if (uart_ar_accept) begin
            // accept UART AR this cycle
            read_active         <= 1'b1;
            current_read_master <= 1'b0;
            read_sel_slave      <= uart_axi_araddr[31:24];
            read_addr_latched   <= uart_axi_araddr;
        end else if (pico_ar_accept) begin
            // accept PICO AR
            read_active         <= 1'b1;
            current_read_master <= 1'b1;
            read_sel_slave      <= pico_axi_araddr[31:24];
            read_addr_latched   <= pico_axi_araddr;
        end else if (read_active) begin
            // wait for response handshake to clear
            if ((current_read_master == 1'b0 && uart_axi_rvalid && uart_axi_rready) ||
                (current_read_master == 1'b1 && pico_axi_rvalid && pico_axi_rready)) begin
                read_active <= 1'b0;
            end
        end

        // ------------ WRITE accept ------------
        if (uart_aw_accept) begin
            write_active         <= 1'b1;
            current_write_master <= 1'b0;
            write_sel_slave      <= uart_axi_awaddr[31:24];
            write_addr_latched   <= uart_axi_awaddr;
        end else if (pico_aw_accept) begin
            write_active         <= 1'b1;
            current_write_master <= 1'b1;
            write_sel_slave      <= pico_axi_awaddr[31:24];
            write_addr_latched   <= pico_axi_awaddr;
        end else if (write_active) begin
            if ((current_write_master == 1'b0 && uart_axi_bvalid && uart_axi_bready) ||
                (current_write_master == 1'b1 && pico_axi_bvalid && pico_axi_bready)) begin
                write_active <= 1'b0;
            end
        end
    end
end


// --- Write address channel ---
assign pico_axi_awready = (current_write_master == 1) ? (
                          (write_active == 1) ? 
                          (write_sel_slave == BRAM_ADDR_OFSET ? bram_axi_awready  :
                           write_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_awready :
                           write_sel_slave == LED_ADDR_OFSET ? led_reg_axi_awready :
                           0) : 0 ) : 0;

assign uart_axi_awready = (current_write_master == 0) ? (
                          (write_active == 1) ? 
                          (write_sel_slave == BRAM_ADDR_OFSET ? bram_axi_awready  :
                           write_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_awready :
                           write_sel_slave == LED_ADDR_OFSET ? led_reg_axi_awready :
                           write_sel_slave == RESET_ADDR_OFSET ? reset_reg_axi_awready : 
                           0) : 0 ) : 0;

// --- Write address output ---
assign bram_axi_awaddr  = (write_addr_latched & ADDR_MASK);
                          
assign bram_axi_awprot  = (current_write_master == 1 && write_sel_slave == BRAM_ADDR_OFSET) ? pico_axi_awprot :
                          (current_write_master == 0 && write_sel_slave == BRAM_ADDR_OFSET) ? uart_axi_awprot : 0;
                          
assign bram_axi_awvalid = write_active == 1 ? 
                          (current_write_master == 1 && write_sel_slave == BRAM_ADDR_OFSET) ? pico_axi_awvalid : 
                          (current_write_master == 0 && write_sel_slave == BRAM_ADDR_OFSET) ? uart_axi_awvalid : 0 : 0;

assign sdram_axi_awaddr  = (write_addr_latched & ADDR_MASK);

assign sdram_axi_awprot  = (current_write_master == 1 && write_sel_slave == SDRAM_ADDR_OFSET) ? pico_axi_awprot :
                           (current_write_master == 0 && write_sel_slave == SDRAM_ADDR_OFSET) ? uart_axi_awprot : 0;

assign sdram_axi_awvalid = (write_active == 1) ? 
                           (current_write_master == 1 && write_sel_slave == SDRAM_ADDR_OFSET) ? pico_axi_awvalid : 
                           (current_write_master == 0 && write_sel_slave == SDRAM_ADDR_OFSET) ? uart_axi_awvalid : 0 : 0;

assign led_reg_axi_awaddr  = (write_addr_latched & ADDR_MASK);

assign led_reg_axi_awvalid = (write_active == 1) ? 
                            (current_write_master == 1 && write_sel_slave == LED_ADDR_OFSET) ? pico_axi_awvalid : 
                            (current_write_master == 0 && write_sel_slave == LED_ADDR_OFSET) ? uart_axi_awvalid : 0 : 0;  

assign reset_reg_axi_awaddr  = (write_addr_latched & ADDR_MASK);

assign reset_reg_axi_awvalid = (write_active == 1) ? 
                              (current_write_master == 0 && write_sel_slave == RESET_ADDR_OFSET) ? uart_axi_awvalid : 0 : 0;

// --- Write data channel
assign pico_axi_wready = (current_write_master == 1) ? (
                         (write_active == 1) ? 
                         (write_sel_slave == BRAM_ADDR_OFSET ? bram_axi_wready  :
                          write_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_wready :
                          write_sel_slave == LED_ADDR_OFSET ? led_reg_axi_wready :
                          0) : 0 ) : 0;

assign uart_axi_wready = (current_write_master == 0) ? (
                         (write_active == 1) ? 
                         (write_sel_slave == BRAM_ADDR_OFSET ? bram_axi_wready  :
                          write_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_wready :
                          write_sel_slave == LED_ADDR_OFSET ? led_reg_axi_wready :
                          write_sel_slave == RESET_ADDR_OFSET ? reset_reg_axi_wready : 
                          0) : 0 ) : 0;

assign bram_axi_wdata  = (current_write_master == 1) ? pico_axi_wdata : 
                         (current_write_master == 0) ? uart_axi_wdata : 0;

assign bram_axi_wstrb  = (current_write_master == 1) ? pico_axi_wstrb : 
                         (current_write_master == 0) ? uart_axi_wstrb : 0;

assign bram_axi_wvalid = (current_write_master == 1 && write_active == 1 && write_sel_slave == BRAM_ADDR_OFSET) ? pico_axi_wvalid :
                         (current_write_master == 0 && write_active == 1 && write_sel_slave == BRAM_ADDR_OFSET) ? uart_axi_wvalid : 0;

assign sdram_axi_wdata  = (current_write_master == 1) ? pico_axi_wdata : 
                          (current_write_master == 0) ? uart_axi_wdata : 0;
assign sdram_axi_wstrb  = (current_write_master == 1) ? pico_axi_wstrb : 
                          (current_write_master == 0) ? uart_axi_wstrb : 0;
assign sdram_axi_wvalid = (current_write_master == 1 && write_active == 1 && write_sel_slave == SDRAM_ADDR_OFSET) ? pico_axi_wvalid :
                          (current_write_master == 0 && write_active == 1 && write_sel_slave == SDRAM_ADDR_OFSET) ? uart_axi_wvalid : 0;

assign led_reg_axi_wdata  = (current_write_master == 1) ? pico_axi_wdata : 
                            (current_write_master == 0) ? uart_axi_wdata : 0;
assign led_reg_axi_wstrb  = (current_write_master == 1) ? pico_axi_wstrb : 
                            (current_write_master == 0) ? uart_axi_wstrb : 0;
assign led_reg_axi_wvalid = (current_write_master == 1 && write_active == 1 && write_sel_slave == LED_ADDR_OFSET) ? pico_axi_wvalid : 
                            (current_write_master == 0 && write_active == 1 && write_sel_slave == LED_ADDR_OFSET) ? uart_axi_wvalid : 0;

assign reset_reg_axi_wdata  = (current_write_master == 0 && write_sel_slave == RESET_ADDR_OFSET) ? uart_axi_wdata : 0;
assign reset_reg_axi_wstrb  = (current_write_master == 0 && write_sel_slave == RESET_ADDR_OFSET) ? uart_axi_wstrb : 0;
assign reset_reg_axi_wvalid = (current_write_master == 0 && write_active == 1 && write_sel_slave == RESET_ADDR_OFSET) ? uart_axi_wvalid : 0;

// --- Write response channel
assign pico_axi_bresp  = (current_write_master == 1) ?
                         (write_sel_slave == BRAM_ADDR_OFSET ? bram_axi_bresp  :
                         write_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_bresp :
                         write_sel_slave == LED_ADDR_OFSET ? led_reg_axi_bresp :
                          0) : 0;

assign pico_axi_bvalid = (current_write_master == 1) ? (
                         (write_active == 1) ? 
                         (write_sel_slave == BRAM_ADDR_OFSET ? bram_axi_bvalid  :
                          write_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_bvalid :
                          write_sel_slave == LED_ADDR_OFSET ? led_reg_axi_bvalid :
                          0) : 0 ) : 0;

assign uart_axi_bresp  = (current_write_master == 0) ?
                         (write_sel_slave == BRAM_ADDR_OFSET ? bram_axi_bresp  :
                         write_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_bresp :
                         write_sel_slave == LED_ADDR_OFSET ? led_reg_axi_bresp :
                         write_sel_slave == RESET_ADDR_OFSET ? reset_reg_axi_bresp :
                          0) : 0;

assign uart_axi_bvalid = (current_write_master == 0) ? (
                         (write_active == 1) ? 
                         (write_sel_slave == BRAM_ADDR_OFSET ? bram_axi_bvalid  :
                          write_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_bvalid :
                          write_sel_slave == LED_ADDR_OFSET ? led_reg_axi_bvalid :
                          write_sel_slave == RESET_ADDR_OFSET ? reset_reg_axi_bvalid :
                          0) : 0 ) : 0;

assign bram_axi_bready  = (current_write_master == 1 && write_active == 1 && write_sel_slave == BRAM_ADDR_OFSET) ? pico_axi_bready :
                          (current_write_master == 0 && write_active == 1 && write_sel_slave == BRAM_ADDR_OFSET) ? uart_axi_bready : 0;
                          
assign sdram_axi_bready = (current_write_master == 1 && write_active == 1 && write_sel_slave == SDRAM_ADDR_OFSET) ? pico_axi_bready : 
                          (current_write_master == 0 && write_active == 1 && write_sel_slave == SDRAM_ADDR_OFSET) ? uart_axi_bready : 0;

assign led_reg_axi_bready = (current_write_master == 1 && write_active == 1 && write_sel_slave == LED_ADDR_OFSET) ? pico_axi_bready : 
                            (current_write_master == 0 && write_active == 1 && write_sel_slave == LED_ADDR_OFSET) ? uart_axi_bready : 0;

assign reset_reg_axi_bready   = (current_write_master == 0 && write_active == 1 && write_sel_slave == RESET_ADDR_OFSET) ? uart_axi_bready : 0;

// --- Read address channel ---
assign pico_axi_arready = (current_read_master == 1) ? (
                          (read_active == 1) ? 
                          (read_sel_slave == BRAM_ADDR_OFSET ? bram_axi_arready  :
                           read_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_arready :
                           read_sel_slave == LED_ADDR_OFSET ? led_reg_axi_arready :
                           0) : 0 ) : 0;

assign uart_axi_arready = (current_read_master == 0) ? (
                          (read_active == 1) ? 
                          (read_sel_slave == BRAM_ADDR_OFSET ? bram_axi_arready  :
                           read_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_arready :
                           read_sel_slave == LED_ADDR_OFSET ? led_reg_axi_arready :
                           read_sel_slave == RESET_ADDR_OFSET ? reset_reg_axi_arready : 0) : 0 ) : 0;

assign bram_axi_araddr  = read_addr_latched & ADDR_MASK; 
                          
assign bram_axi_arprot  = (current_read_master == 1 && read_sel_slave == BRAM_ADDR_OFSET) ? pico_axi_arprot :
                          (current_read_master == 0 && read_sel_slave == BRAM_ADDR_OFSET) ? uart_axi_arprot : 0;
                          
assign bram_axi_arvalid = (read_active == 1) ? 
                          (current_read_master == 1 && read_sel_slave == BRAM_ADDR_OFSET) ? pico_axi_arvalid : 
                          (current_read_master == 0 && read_sel_slave == BRAM_ADDR_OFSET) ? uart_axi_arvalid : 0 : 0;

assign sdram_axi_araddr  = (read_addr_latched & ADDR_MASK);

assign sdram_axi_arprot  = (current_read_master == 1 && read_sel_slave == SDRAM_ADDR_OFSET) ? pico_axi_arprot : 
                           (current_read_master == 0 && read_sel_slave == SDRAM_ADDR_OFSET) ? uart_axi_arprot : 0;

assign sdram_axi_arvalid = (read_active == 1) ? 
                           (current_read_master == 1 && read_sel_slave == SDRAM_ADDR_OFSET) ? pico_axi_arvalid : 
                           (current_read_master == 0 && read_sel_slave == SDRAM_ADDR_OFSET) ? uart_axi_arvalid : 0 : 0;

assign led_reg_axi_araddr  = (read_addr_latched & ADDR_MASK);

assign led_reg_axi_arvalid = (read_active == 1) ? 
                            (current_read_master == 1 && read_sel_slave == LED_ADDR_OFSET) ? pico_axi_arvalid : 
                            (current_read_master == 0 && read_sel_slave == LED_ADDR_OFSET) ? uart_axi_arvalid : 0 : 0;

assign reset_reg_axi_araddr  = (read_addr_latched & ADDR_MASK);

assign reset_reg_axi_arvalid = (read_active == 1) ? 
                              (current_read_master == 0 && read_sel_slave == RESET_ADDR_OFSET) ? uart_axi_arvalid : 0 : 0;

// --- Read data channel ---
assign pico_axi_rdata  = (current_read_master == 1) ? (
                         (read_sel_slave == BRAM_ADDR_OFSET ? bram_axi_rdata  :
                         read_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_rdata :
                         read_sel_slave == LED_ADDR_OFSET ? led_reg_axi_rdata :
                          0) ) : 0;
                         
assign pico_axi_rresp  = (current_read_master == 1) ? (
                         (read_sel_slave == BRAM_ADDR_OFSET ? bram_axi_rresp  :
                         read_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_rresp :
                         read_sel_slave == LED_ADDR_OFSET ? led_reg_axi_rresp :
                          0) ) : 0;
                         
assign pico_axi_rvalid = (current_read_master == 1) ? (
                         (read_active == 1) ? 
                         (read_sel_slave == BRAM_ADDR_OFSET ? bram_axi_rvalid  :
                          read_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_rvalid :
                          read_sel_slave == LED_ADDR_OFSET ? led_reg_axi_rvalid :
                          0) : 0 ) : 0;

assign uart_axi_rdata  = (current_read_master == 0) ? (
                         (read_sel_slave == BRAM_ADDR_OFSET ? bram_axi_rdata  :
                         read_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_rdata :
                         read_sel_slave == LED_ADDR_OFSET ? led_reg_axi_rdata :
                         read_sel_slave == RESET_ADDR_OFSET ? reset_reg_axi_rdata :
                          0) ) : 0;
assign uart_axi_rresp  = (current_read_master == 0) ? (
                         (read_sel_slave == BRAM_ADDR_OFSET ? bram_axi_rresp  :
                         read_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_rresp :
                         read_sel_slave == LED_ADDR_OFSET ? led_reg_axi_rresp :
                         read_sel_slave == RESET_ADDR_OFSET ? reset_reg_axi_rresp :
                          0) ) : 0;
assign uart_axi_rvalid = (current_read_master == 0) ? (
                         (read_active == 1) ? 
                         (read_sel_slave == BRAM_ADDR_OFSET ? bram_axi_rvalid  :
                          read_sel_slave == SDRAM_ADDR_OFSET ? sdram_axi_rvalid :
                          read_sel_slave == LED_ADDR_OFSET ? led_reg_axi_rvalid :
                          read_sel_slave == RESET_ADDR_OFSET ? reset_reg_axi_rvalid : 0) : 0 ) : 0;

assign bram_axi_rready  = (current_read_master == 1 && read_active == 1 && read_sel_slave == BRAM_ADDR_OFSET) ? pico_axi_rready :
                          (current_read_master == 0 && read_active == 1 && read_sel_slave == BRAM_ADDR_OFSET) ? uart_axi_rready : 0;

assign sdram_axi_rready = (current_read_master == 1 && read_active == 1 && read_sel_slave == SDRAM_ADDR_OFSET) ? pico_axi_rready : 
                          (current_read_master == 0 && read_active == 1 && read_sel_slave == SDRAM_ADDR_OFSET) ? uart_axi_rready : 0;

assign led_reg_axi_rready = (current_read_master == 1 && read_active == 1 && read_sel_slave == LED_ADDR_OFSET) ? pico_axi_rready :
                            (current_read_master == 0 && read_active == 1 && read_sel_slave == LED_ADDR_OFSET) ? uart_axi_rready : 0;

assign reset_reg_axi_rready   = (current_read_master == 0 && read_active == 1 && read_sel_slave == RESET_ADDR_OFSET) ? uart_axi_rready : 0;

endmodule
