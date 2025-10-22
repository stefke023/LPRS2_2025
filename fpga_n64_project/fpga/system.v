`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/12/2025 10:12:53 AM
// Design Name: 
// Module Name: system
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//`define SYM

module system #(
    parameter PERIOD = 20,
    parameter CLK_FREQ =  50000000,
    parameter BAUD_RATE = 115200
    )(
	input wire          i_clk,
	input wire          i_rstn,
	output reg [7:0]    o_led,
	
	// UART interface
	input  wire         i_serial_rx,
	output wire         o_serial_tx,
	output wire         on_serial_cts,
	output wire         on_serial_dsr,	
	
    // SDRAM control
    output wire          o_ram_clk,
    output wire          o_ram_cs_n,
    output wire          o_ram_cke,
    output wire          o_ram_ras_n, 
    output wire          o_ram_cas_n, 
    output wire          o_ram_we_n,
    output wire  [ 1:0]  o_ram_bs,
    output wire  [11:0]  o_ram_addr,
    //output wire          o_ram_dmod,
    inout  wire [15:0]   io_ram_data,
    output wire  [ 1:0]  o_ram_dqm,
    //, output wire          locked
    //, output wire [DW-1:0]  o_debug
    

    //N64 controller
    inout wire io_n64_joypad_1,
	 
	 //FPGA to PC
	 output wire o_tx
    );
    
     
    
`ifdef SYM
	reg			  s_sdram_clk;
	reg 		  n_rst;
	reg	   [ 5:0] pll_clk;
`else
	wire		  s_sdram_clk;
	wire 		  n_rst;
`endif   
    wire   [ 1:0] startup_state;						//TODO remove
    
`ifdef SYM
	//fake pll locked
	always @(posedge i_clk) begin
		if(!i_rstn) begin
			n_rst 	 <= 0;
			pll_clk  <= 0;
		end else
			if(pll_clk == 50) begin
				n_rst <= 1;
				pll_clk <= 50;
			end 
			else
				pll_clk <= pll_clk + 1;
	end
`else	

`endif
	//assign state  = startup_state;		//TODO remove
	
`ifdef SYM
	reg			  s_sys_clk;
`else	
	wire		  s_sys_clk;
`endif

wire n64_clk;

`ifdef SYM

	//TODO fake pll
    always 
	begin
		s_sys_clk <= 1'b1; 
		s_sdram_clk <= 1'b0;
		#(PERIOD/2); //

		s_sys_clk <= 1'b0;
		s_sdram_clk <= 1'b1;
		#(PERIOD/2); 
	end
`endif

wire pll_rst;
assign pll_rst = ~i_rstn;

	sdram_pll pll1(
		.areset		(pll_rst),
		.inclk0		(i_clk),
		.c0			(s_sys_clk),
		.c1			(s_sdram_clk),
		.c2         (n64_clk),
		.locked		(n_rst)
	);
	
//moved here for simulation purposes
	
	wire 		so_ram_we_n;
	wire [15:0] so_ram_data;
    wire [15:0] si_ram_data;

	assign io_ram_data 	= !so_ram_we_n ? so_ram_data : 16'bZ;
	assign si_ram_data 	= io_ram_data;
	assign o_ram_we_n	= so_ram_we_n;
	assign o_ram_clk	= s_sdram_clk; 


    reg           rst_proc;
    // Pico AXI4-Lite master memory interface
    wire          pico_axi_awvalid;
    wire          pico_axi_awready;
    wire   [31:0] pico_axi_awaddr;
    wire   [ 2:0] pico_axi_awprot;

    
    wire          pico_axi_wvalid;
    wire          pico_axi_wready;
    wire   [31:0] pico_axi_wdata;
    wire   [ 3:0] pico_axi_wstrb;
    
    wire          pico_axi_bvalid;
    wire          pico_axi_bready;
    
    wire          pico_axi_arvalid;
    wire          pico_axi_arready;
    wire   [31:0] pico_axi_araddr;
    wire   [ 2:0] pico_axi_arprot;    
    
    wire          pico_axi_rvalid;
    wire          pico_axi_rready;
    wire   [31:0] pico_axi_rdata;
    
    // Pico Co-Processor Interface
	wire 	      s_pcpi_valid;
	wire   [31:0] s_pcpi_insn;
	wire   [31:0] s_pcpi_rs1;
	wire   [31:0] s_pcpi_rs2;
	wire		  s_pcpi_wr;
	wire   [31:0] s_pcpi_rd;
	wire		  s_pcpi_wait;
	wire		  s_pcpi_ready;
		
	// IRQ interface
	wire   [31:0] s_irq;
	wire   [31:0] s_eoi;
	
	// Other // Trace interface
	wire		  s_trace_valid;
	wire   [35:0] s_trace_data;
	wire 		  instr;
	
	// UART-DMA AXI4-lite master memory interface
	wire          uart_axi_awvalid;
    wire          uart_axi_awready;
    wire   [31:0] uart_axi_awaddr;
    wire   [ 2:0] uart_axi_awprot;
    
    wire          uart_axi_wvalid;
    wire          uart_axi_wready;
    wire   [31:0] uart_axi_wdata;
    wire   [ 3:0] uart_axi_wstrb;
    
    wire          uart_axi_bvalid;
    wire          uart_axi_bready;
    wire   [ 1:0] uart_axi_bresp;
    
    wire          uart_axi_arvalid;
    wire          uart_axi_arready;
    wire   [31:0] uart_axi_araddr;
    wire   [ 2:0] uart_axi_arprot;
    
    wire          uart_axi_rvalid;
    wire          uart_axi_rready;
    wire   [ 1:0] uart_axi_rresp;
    wire   [31:0] uart_axi_rdata;
    
    // BRAM AXI4-Lite Slave Interface
    wire   [31:0] bram_axi_awaddr;
    wire          bram_axi_awvalid;
    
    wire   [ 2:0] bram_axi_awprot;
    wire          bram_axi_awready;

    wire   [31:0] bram_axi_wdata;
    wire   [ 3:0] bram_axi_wstrb;
    wire          bram_axi_wvalid;
    wire          bram_axi_wready;

    wire   [ 1:0] bram_axi_bresp;
    wire          bram_axi_bvalid;
    wire          bram_axi_bready;

    wire   [31:0] bram_axi_araddr;
    wire          bram_axi_arvalid;
    wire   [ 2:0] bram_axi_arprot;
    wire          bram_axi_arready;

    wire   [31:0] bram_axi_rdata;
    wire   [ 1:0] bram_axi_rresp;
    wire          bram_axi_rvalid;
    wire          bram_axi_rready;
    
    // SDRAM AXI4-Lite Slave Interface
    wire   [31:0] sdram_axi_awaddr;
    wire          sdram_axi_awvalid;
    
    wire   [ 2:0] sdram_axi_awprot;
    wire          sdram_axi_awready;

    wire   [31:0] sdram_axi_wdata;
    wire   [ 3:0] sdram_axi_wstrb;
    wire          sdram_axi_wvalid;
    wire          sdram_axi_wready;

    wire   [ 1:0] sdram_axi_bresp;
    wire          sdram_axi_bvalid;
    wire          sdram_axi_bready;

    wire   [31:0] sdram_axi_araddr;
    wire          sdram_axi_arvalid;
    wire   [ 2:0] sdram_axi_arprot;
    wire          sdram_axi_arready;

    wire   [31:0] sdram_axi_rdata;
    wire   [ 1:0] sdram_axi_rresp;
    wire          sdram_axi_rvalid;
    wire          sdram_axi_rready;
    
    // Memory Mapped Register for LED AXI4-Lite Slave Interface
    wire   [31:0] led_reg_axi_awaddr;
    wire          led_reg_axi_awvalid;
    
    wire   [ 2:0] led_reg_axi_awprot;
    wire          led_reg_axi_awready;

    wire   [31:0] led_reg_axi_wdata;
    wire   [ 3:0] led_reg_axi_wstrb;
    wire          led_reg_axi_wvalid;
    wire          led_reg_axi_wready;

    wire   [ 1:0] led_reg_axi_bresp;
    wire          led_reg_axi_bvalid;
    wire          led_reg_axi_bready;

    wire   [31:0] led_reg_axi_araddr;
    wire          led_reg_axi_arvalid;
    wire   [ 2:0] led_reg_axi_arprot;
    wire          led_reg_axi_arready;

    wire   [31:0] led_reg_axi_rdata;
    wire   [ 1:0] led_reg_axi_rresp;
    wire          led_reg_axi_rvalid;
    wire          led_reg_axi_rready;
    wire   [31:0] led_reg_data;
    
    
    // Memory Mapped Register for RESET AXI4-Lite Slave Interface
    wire   [31:0] reset_reg_axi_awaddr;
    wire          reset_reg_axi_awvalid;
    
    wire   [ 2:0] reset_reg_axi_awprot;
    wire          reset_reg_axi_awready;

    wire   [31:0] reset_reg_axi_wdata;
    wire   [ 3:0] reset_reg_axi_wstrb;
    wire          reset_reg_axi_wvalid;
    wire          reset_reg_axi_wready;

    wire   [ 1:0] reset_reg_axi_bresp;
    wire          reset_reg_axi_bvalid;
    wire          reset_reg_axi_bready;

    wire   [31:0] reset_reg_axi_araddr;
    wire          reset_reg_axi_arvalid;
    wire   [ 2:0] reset_reg_axi_arprot;
    wire          reset_reg_axi_arready;

    wire   [31:0] reset_reg_axi_rdata;
    wire   [ 1:0] reset_reg_axi_rresp;
    wire          reset_reg_axi_rvalid;
    wire          reset_reg_axi_rready;
    wire   [31:0] reset_reg_data;



    //N64 controller
    reg [33:0] n64_reg_buttons;
    wire n64_alive; 
    wire [33:0] n64_buttons;
    wire [7:0] output_byte;
	 
    //Resen
	
    picorv32_axi #(.ENABLE_PCPI(1), .ENABLE_MUL(1)
    ) picorv32(
        .clk            (i_clk        ),
		.resetn         (i_rstn         ),
		
		//AXI4-lite master memory interface
		.mem_axi_awvalid (pico_axi_awvalid),
		.mem_axi_awready (pico_axi_awready),
		.mem_axi_awaddr  (pico_axi_awaddr ),
		.mem_axi_awprot  (pico_axi_awprot ),
		.mem_axi_wvalid  (pico_axi_wvalid ),
		.mem_axi_wready  (pico_axi_wready ),
		.mem_axi_wdata   (pico_axi_wdata  ),
		.mem_axi_wstrb   (pico_axi_wstrb  ),
		.mem_axi_bvalid  (pico_axi_bvalid ),
		.mem_axi_bready  (pico_axi_bready ),
		.mem_axi_arvalid (pico_axi_arvalid),
		.mem_axi_arready (pico_axi_arready),
		.mem_axi_araddr  (pico_axi_araddr ),
		.mem_axi_arprot  (pico_axi_arprot ),
		.mem_axi_rvalid  (pico_axi_rvalid ),
		.mem_axi_rready  (pico_axi_rready ),
		.mem_axi_rdata   (pico_axi_rdata  ),  
		
		// Pico Co-Processor Interface
		.pcpi_valid     (s_pcpi_valid  ),
		.pcpi_insn	    (s_pcpi_insn   ),	
		.pcpi_rs1	    (s_pcpi_rs1	   ),	
		.pcpi_rs2	    (s_pcpi_rs2    ),	
		.pcpi_wr		(s_pcpi_wr	   ),	
		.pcpi_rd		(s_pcpi_rd	   ), 
		.pcpi_wait	    (s_pcpi_wait   ),	
		.pcpi_ready	    (s_pcpi_ready  ),  			
		
		// IRQ interface
		.irq			(s_irq		   ),	
		.eoi			(s_eoi		   ),	
		//Other
		.trace_valid    (s_trace_valid ),	
		.trace_data	    (s_trace_data  )	
		
    );
    
    //Resen
    picorv32_pcpi_mul pcpi_mul(
		.clk			(i_clk     ),
		.resetn		    (i_rstn        ),
		.pcpi_valid	    (s_pcpi_valid  ),
		.pcpi_insn	    (s_pcpi_insn   ),
		.pcpi_rs1	    (s_pcpi_rs1    ),
		.pcpi_rs2	    (s_pcpi_rs2    ),
		.pcpi_wr		(s_pcpi_wr     ),
		.pcpi_rd		(s_pcpi_rd     ),
		.pcpi_wait	    (s_pcpi_wait   ),
		.pcpi_ready	    (s_pcpi_ready  )
	);
	
	wire temp, temp2;
    //Resen
	uart_axi #(
        .CLK_FREQ(CLK_FREQ  ),
        .BAUD_RATE(BAUD_RATE)
    ) uart (
	    .clk             (i_clk      ),
		.resetn          (i_rstn         ),
		
	    // AXI4-lite master memory interface
	    .uart_axi_awvalid (uart_axi_awvalid),
		.uart_axi_awready (uart_axi_awready),
		.uart_axi_awaddr  (uart_axi_awaddr ),
		.uart_axi_awprot  (uart_axi_awprot ),
		.uart_axi_wvalid  (uart_axi_wvalid ),
		.uart_axi_wready  (uart_axi_wready ),
		.uart_axi_wdata   (uart_axi_wdata  ),
		.uart_axi_wstrb   (uart_axi_wstrb  ),
		.uart_axi_bresp   (uart_axi_bresp  ),
        .uart_axi_bvalid  (uart_axi_bvalid ),
		.uart_axi_bready  (uart_axi_bready ),
		.uart_axi_arvalid (uart_axi_arvalid),
		.uart_axi_arready (uart_axi_arready),
		.uart_axi_araddr  (uart_axi_araddr ),
		.uart_axi_arprot  (uart_axi_arprot ),
		.uart_axi_rvalid  (uart_axi_rvalid ),
        .uart_axi_rresp   (uart_axi_rresp  ),
		.uart_axi_rready  (uart_axi_rready ),
		.uart_axi_rdata   (uart_axi_rdata  ),   
		
		// UART interface
	    .i_serial_rx     (temp2    ), //i_serial_tx
	    .o_serial_tx     (temp     ), //o_serial_tx
	    .on_serial_cts   (on_serial_cts   ),
	    .on_serial_dsr   (on_serial_dsr   )
	);
	
	
	//assign output_byte = o_led;
	
	uart_tx transmitter(
		.i_Clk       (i_clk),
    .i_TX_DV       (1'b1),
    .i_TX_Byte    (o_led),
    .o_TX_Active  (),
    .o_TX_Serial  (o_tx),
    .o_TX_Done    ()
	);
		
    //Resen
    axi_lite_arbiter arbiter (
        .clk               (i_clk ),
        .resetn            (i_rstn    ),
        .processor_reset   (rst_proc ),
        // Pico AXI4-Lite master memory interface
        .pico_axi_awvalid  (pico_axi_awvalid  ),
        .pico_axi_awaddr   (pico_axi_awaddr   ),
        .pico_axi_awprot   (pico_axi_awprot   ),
        .pico_axi_awready  (pico_axi_awready  ),
        
        .pico_axi_wvalid   (pico_axi_wvalid   ),
        .pico_axi_wready   (pico_axi_wready   ),
        .pico_axi_wdata    (pico_axi_wdata    ),
        .pico_axi_wstrb    (pico_axi_wstrb    ),
        
       // .pico_axi_bresp    (pico_axi_bresp    ),
        .pico_axi_bvalid   (pico_axi_bvalid   ),
        .pico_axi_bready   (pico_axi_bready   ),
        
        .pico_axi_arvalid  (pico_axi_arvalid  ),
        .pico_axi_araddr   (pico_axi_araddr   ),
        .pico_axi_arprot   (pico_axi_arprot   ),
        .pico_axi_arready  (pico_axi_arready  ),
        
        .pico_axi_rvalid   (pico_axi_rvalid   ),
        .pico_axi_rdata    (pico_axi_rdata    ),
        //.pico_axi_rresp    (pico_axi_rresp    ),
        .pico_axi_rready   (pico_axi_rready   ),
        
        // UART-DMA AXI4-lite master memory interface
        .uart_axi_awvalid  (uart_axi_awvalid  ),
        .uart_axi_awaddr   (uart_axi_awaddr   ),
        .uart_axi_awprot   (uart_axi_awprot   ),
        .uart_axi_awready  (uart_axi_awready  ),
        
        .uart_axi_wvalid   (uart_axi_wvalid   ),
        .uart_axi_wdata    (uart_axi_wdata    ),
        .uart_axi_wstrb    (uart_axi_wstrb    ),
        .uart_axi_wready   (uart_axi_wready   ),
        
        .uart_axi_bresp    (uart_axi_bresp    ),
        .uart_axi_bvalid   (uart_axi_bvalid   ),
        .uart_axi_bready   (uart_axi_bready   ),
        
        .uart_axi_arvalid  (uart_axi_arvalid  ),
        .uart_axi_araddr   (uart_axi_araddr   ),
        .uart_axi_arprot   (uart_axi_arprot   ),
        .uart_axi_arready  (uart_axi_arready  ),
        
        .uart_axi_rvalid   (uart_axi_rvalid   ),
        .uart_axi_rdata    (uart_axi_rdata    ),
        .uart_axi_rresp    (uart_axi_rresp    ),
        .uart_axi_rready   (uart_axi_rready   ),
        
         // BRAM AXI4-Lite Slave Interface
        .bram_axi_awaddr   (bram_axi_awaddr   ),
        .bram_axi_awvalid  (bram_axi_awvalid  ),
        .bram_axi_awprot   (bram_axi_awprot   ),
        .bram_axi_awready  (bram_axi_awready  ),
    
        .bram_axi_wdata    (bram_axi_wdata    ),
        .bram_axi_wstrb    (bram_axi_wstrb    ),
        .bram_axi_wvalid   (bram_axi_wvalid   ),
        .bram_axi_wready   (bram_axi_wready   ),
    
        .bram_axi_bresp    (bram_axi_bresp    ),
        .bram_axi_bvalid   (bram_axi_bvalid   ),
        .bram_axi_bready   (bram_axi_bready   ),
    
        .bram_axi_araddr   (bram_axi_araddr   ),
        .bram_axi_arvalid  (bram_axi_arvalid  ),
        .bram_axi_arprot   (bram_axi_arprot   ),
        .bram_axi_arready  (bram_axi_arready  ),
    
        .bram_axi_rdata    (bram_axi_rdata    ),
        .bram_axi_rresp    (bram_axi_rresp    ),
        .bram_axi_rvalid   (bram_axi_rvalid   ),
        .bram_axi_rready   (bram_axi_rready   ),
        
         // SDRAM AXI4-Lite Slave Interface
        .sdram_axi_awaddr  (sdram_axi_awaddr  ),
        .sdram_axi_awvalid (sdram_axi_awvalid ),
        .sdram_axi_awprot  (sdram_axi_awprot  ),
        .sdram_axi_awready (sdram_axi_awready ),
    
        .sdram_axi_wdata   (sdram_axi_wdata   ),
        .sdram_axi_wstrb   (sdram_axi_wstrb   ),
        .sdram_axi_wvalid  (sdram_axi_wvalid  ),
        .sdram_axi_wready  (sdram_axi_wready  ),
    
        .sdram_axi_bresp   (sdram_axi_bresp   ),
        .sdram_axi_bvalid  (sdram_axi_bvalid  ),
        .sdram_axi_bready  (sdram_axi_bready  ),
    
        .sdram_axi_araddr  (sdram_axi_araddr  ),
        .sdram_axi_arvalid (sdram_axi_arvalid ),
        .sdram_axi_arprot  (sdram_axi_arprot  ),
        .sdram_axi_arready (sdram_axi_arready ),
    
        .sdram_axi_rdata   (sdram_axi_rdata   ),
        .sdram_axi_rresp   (sdram_axi_rresp   ),
        .sdram_axi_rvalid  (sdram_axi_rvalid  ),
        .sdram_axi_rready  (sdram_axi_rready  ),
        
         // Memory Mapped Registers AXI4-Lite Slave Interface
        .led_reg_axi_awaddr  (led_reg_axi_awaddr  ),
        .led_reg_axi_awvalid (led_reg_axi_awvalid ),
        //.led_reg_axi_awprot  (led_reg_axi_awprot  ),
        .led_reg_axi_awready (led_reg_axi_awready ),
    
        .led_reg_axi_wdata   (led_reg_axi_wdata   ),
        .led_reg_axi_wstrb   (led_reg_axi_wstrb   ),
        .led_reg_axi_wvalid  (led_reg_axi_wvalid  ),
        .led_reg_axi_wready  (led_reg_axi_wready  ),
    
        .led_reg_axi_bresp   (led_reg_axi_bresp   ),
        .led_reg_axi_bvalid  (led_reg_axi_bvalid  ),
        .led_reg_axi_bready  (led_reg_axi_bready  ),
    
        .led_reg_axi_araddr  (led_reg_axi_araddr  ),
        .led_reg_axi_arvalid (led_reg_axi_arvalid ),
        //.led_reg_axi_arprot  (led_reg_axi_arprot  ),
        .led_reg_axi_arready (led_reg_axi_arready ),
    
        .led_reg_axi_rdata   (led_reg_axi_rdata   ),
        .led_reg_axi_rresp   (led_reg_axi_rresp   ),
        .led_reg_axi_rvalid  (led_reg_axi_rvalid  ),
        .led_reg_axi_rready  (led_reg_axi_rready  ),
        
         // Reset Reg AXI4-Lite Slave Interface
        .reset_reg_axi_awaddr    (reset_reg_axi_awaddr    ),
        .reset_reg_axi_awvalid   (reset_reg_axi_awvalid   ),
        //.reset_reg_axi_awprot    (reset_reg_axi_awprot    ),
        .reset_reg_axi_awready   (reset_reg_axi_awready   ),
    
        .reset_reg_axi_wdata     (reset_reg_axi_wdata     ),
        .reset_reg_axi_wstrb     (reset_reg_axi_wstrb     ),
        .reset_reg_axi_wvalid    (reset_reg_axi_wvalid    ),
        .reset_reg_axi_wready    (reset_reg_axi_wready    ),
    
        .reset_reg_axi_bresp     (reset_reg_axi_bresp     ),
        .reset_reg_axi_bvalid    (reset_reg_axi_bvalid    ),
        .reset_reg_axi_bready    (reset_reg_axi_bready    ),
    
        .reset_reg_axi_araddr    (reset_reg_axi_araddr    ),
        .reset_reg_axi_arvalid   (reset_reg_axi_arvalid   ),
        //.reset_reg_axi_arprot    (reset_reg_axi_arprot    ),
        .reset_reg_axi_arready   (reset_reg_axi_arready   ),
    
        .reset_reg_axi_rdata     (reset_reg_axi_rdata     ),
        .reset_reg_axi_rresp     (reset_reg_axi_rresp     ),
        .reset_reg_axi_rvalid    (reset_reg_axi_rvalid    ),
        .reset_reg_axi_rready    (reset_reg_axi_rready    )
       
    );

    //Resen
    bram_axi_sp bram (
    
         // BRAM AXI4-Lite Slave Interface
        .mem_axi_aclk      (i_clk         ),
        .mem_axi_aresetn   (i_rstn            ),
    
        .mem_axi_awaddr    (bram_axi_awaddr   ),
        .mem_axi_awvalid   (bram_axi_awvalid  ),
        .mem_axi_awready   (bram_axi_awready  ),
    
        .mem_axi_wdata     (bram_axi_wdata    ),
        .mem_axi_wvalid    (bram_axi_wvalid   ),
        .mem_axi_wready    (bram_axi_wready   ),
    
        .mem_axi_bresp     (bram_axi_bresp    ),
        .mem_axi_bvalid    (bram_axi_bvalid   ),
        .mem_axi_bready    (bram_axi_bready   ),
    
        .mem_axi_araddr    (bram_axi_araddr   ),
        .mem_axi_arvalid   (bram_axi_arvalid  ),
        .mem_axi_arready   (bram_axi_arready  ),
    
        .mem_axi_rdata     (bram_axi_rdata    ),
        .mem_axi_rresp     (bram_axi_rresp    ),
        .mem_axi_rvalid    (bram_axi_rvalid   ),
        .mem_axi_rready    (bram_axi_rready   )
    );

    //Resen
    sdram_ctrl_axi sdram_ctrl (
    
        // SDRAM AXI4-Lite Slave Interface
        .sdram_axi_aclk    (i_clk       ),
        .sdram_axi_aresetn (i_rstn            ),
    
        .sdram_axi_awvalid (sdram_axi_awvalid ),
        .sdram_axi_awready (sdram_axi_awready ),
        .sdram_axi_awaddr  (sdram_axi_awaddr  ),
    
        .sdram_axi_wvalid  (sdram_axi_wvalid  ),
        .sdram_axi_wready  (sdram_axi_wready  ),
        .sdram_axi_wdata   (sdram_axi_wdata   ),
        .sdram_axi_wstrb   (sdram_axi_wstrb   ),
    
        .sdram_axi_bvalid  (sdram_axi_bvalid  ),
        .sdram_axi_bready  (sdram_axi_bready  ),
    
        .sdram_axi_arvalid (sdram_axi_arvalid ),
        .sdram_axi_arready (sdram_axi_arready ),
        .sdram_axi_araddr  (sdram_axi_araddr  ),
    
        .sdram_axi_rvalid  (sdram_axi_rvalid  ),
        .sdram_axi_rready  (sdram_axi_rready  ),
        .sdram_axi_rdata   (sdram_axi_rdata   ),
    
        // SDRAM control
        .o_ram_cs_n        (o_ram_cs_n        ),
        .o_ram_cke         (o_ram_cke         ),
        .o_ram_ras_n       (o_ram_ras_n       ),
        .o_ram_cas_n       (o_ram_cas_n       ), 
        .o_ram_we_n        (so_ram_we_n        ),
        .o_ram_bs          (o_ram_bs          ),
        .o_ram_addr        (o_ram_addr        ),
        //.o_ram_dmod        (o_ram_dmod        ),
        .i_ram_data        (si_ram_data        ),
        .o_ram_data        (so_ram_data        ),
        .o_ram_dqm         (o_ram_dqm         )
    );

    //Resen
    mmreg_axi led_reg (
    
        // Memory Mapped Registers AXI4-Lite Slave Interface
        .mmreg_axi_aclk    (i_clk      ),
        .mmreg_axi_aresetn (i_rstn         ),
        
        .mmreg_axi_awaddr  (led_reg_axi_awaddr  ),
        .mmreg_axi_awvalid (led_reg_axi_awvalid ),
        //.mmreg_axi_awprot  (led_reg_axi_awprot  ),
        .mmreg_axi_awready (led_reg_axi_awready ),
    
        .mmreg_axi_wdata   (led_reg_axi_wdata   ),
        .mmreg_axi_wstrb   (led_reg_axi_wstrb   ),
        .mmreg_axi_wvalid  (led_reg_axi_wvalid  ),
        .mmreg_axi_wready  (led_reg_axi_wready  ),
    
        .mmreg_axi_bresp   (led_reg_axi_bresp   ),
        .mmreg_axi_bvalid  (led_reg_axi_bvalid  ),
        .mmreg_axi_bready  (led_reg_axi_bready  ),
    
        .mmreg_axi_araddr  (led_reg_axi_araddr  ),
        .mmreg_axi_arvalid (led_reg_axi_arvalid ),
        //.mmreg_axi_arprot  (led_reg_axi_arprot  ),
        .mmreg_axi_arready (led_reg_axi_arready ),
    
        .mmreg_axi_rdata   (led_reg_axi_rdata   ),
        .mmreg_axi_rresp   (led_reg_axi_rresp   ),
        .mmreg_axi_rvalid  (led_reg_axi_rvalid  ),
        .mmreg_axi_rready  (led_reg_axi_rready  ),
        .mmreg_out_data    (led_reg_data        )
    );

    //Resen
    N64_controller n64_controller(
        .clk_50MHZ        (n64_clk),
        .data             (io_n64_joypad_1),
        .start            (1'b1) ,	
	    .buttons          (n64_buttons[33:0]),
	    .alive            (n64_alive)
    );
    
    mmreg_axi #(
        .TARG_ADDR(32'h00000200),
        .IS_RST_REG(1'b1)
    ) reset_reg (
    
        // CAN IP Slave Interface
        .mmreg_axi_aclk     (i_clk ),
        .mmreg_axi_aresetn  (i_rstn),
        
        .mmreg_axi_awaddr   (reset_reg_axi_awaddr    ),
        .mmreg_axi_awvalid  (reset_reg_axi_awvalid   ),
        //.mmreg_axi_awprot   (reset_reg_axi_awprot)
        .mmreg_axi_awready  (reset_reg_axi_awready   ),
    
        .mmreg_axi_wdata    (reset_reg_axi_wdata     ),
        .mmreg_axi_wstrb    (reset_reg_axi_wstrb     ),
        .mmreg_axi_wvalid   (reset_reg_axi_wvalid    ),
        .mmreg_axi_wready   (reset_reg_axi_wready    ),
    
        .mmreg_axi_bresp    (reset_reg_axi_bresp     ),
        .mmreg_axi_bvalid   (reset_reg_axi_bvalid    ),
        .mmreg_axi_bready   (reset_reg_axi_bready    ),
    
        .mmreg_axi_araddr   (reset_reg_axi_araddr    ),
        .mmreg_axi_arvalid  (reset_reg_axi_arvalid   ),
        //.mmreg_axi_arprot   (reset_reg_axi_arprot    ),
        .mmreg_axi_arready  (reset_reg_axi_arready   ),
    
        .mmreg_axi_rdata    (reset_reg_axi_rdata     ),
        .mmreg_axi_rresp    (reset_reg_axi_rresp     ),
        .mmreg_axi_rvalid   (reset_reg_axi_rvalid    ),
        .mmreg_axi_rready   (reset_reg_axi_rready    ),
        .mmreg_out_data     (reset_reg_data          )
        
        );

    always @(posedge i_clk or negedge i_rstn) begin 
        if (!i_rstn) 
            n64_reg_buttons <= 34'd0;
        else 
            n64_reg_buttons <= n64_buttons;
				
    end 
	 
	 always @(posedge i_clk or negedge i_rstn) begin
		if (!i_rstn) begin
        o_led <= 8'b00000000;
		end else begin
        if (n64_reg_buttons[1] == 1'b1)
            o_led <= 8'b00000001;
        else if (n64_reg_buttons[2] == 1'b1)
            o_led <= 8'b00000010;
        else if (n64_reg_buttons[3] == 1'b1)
            o_led <= 8'b00000011;
        else if (n64_reg_buttons[4] == 1'b1)
            o_led <= 8'b00000100;
        else if (n64_reg_buttons[5] == 1'b1)
            o_led <= 8'b00000101;
        else if (n64_reg_buttons[6] == 1'b1)
            o_led <= 8'b00000110;
        else if (n64_reg_buttons[7] == 1'b1)
            o_led <= 8'b00000111;
        else if (n64_reg_buttons[8] == 1'b1)
            o_led <= 8'b00001000;
        else if (n64_reg_buttons[9] == 1'b1)
            o_led <= 8'b00001001;
        else if (n64_reg_buttons[10] == 1'b1)
            o_led <= 8'b00001010;
        else if (n64_reg_buttons[11] == 1'b1)
            o_led <= 8'b00001011;
        else if (n64_reg_buttons[12] == 1'b1)
            o_led <= 8'b00001100;
        else if (n64_reg_buttons[13] == 1'b1)
            o_led <= 8'b00001101;
        else if (n64_reg_buttons[14] == 1'b1)
            o_led <= 8'b00001110;
        else if (n64_reg_buttons[15] == 1'b1)
            o_led <= 8'b00001111;
        else if (n64_reg_buttons[16] == 1'b1)
            o_led <= 8'b00010000;
        else if (n64_reg_buttons[17] == 1'b1)
            o_led <= 8'b00010001;
        else if (n64_reg_buttons[18] == 1'b1)
            o_led <= 8'b00010010;
        else if (n64_reg_buttons[19] == 1'b1)
            o_led <= 8'b00010011;
        else if (n64_reg_buttons[20] == 1'b1)
            o_led <= 8'b00010100;
        else if (n64_reg_buttons[21] == 1'b1)
            o_led <= 8'b00010101;
        else if (n64_reg_buttons[22] == 1'b1)
            o_led <= 8'b00010110;
        else if (n64_reg_buttons[23] == 1'b1)
            o_led <= 8'b00010111;
        else if (n64_reg_buttons[24] == 1'b1)
            o_led <= 8'b00011000;
        else if (n64_reg_buttons[25] == 1'b1)
            o_led <= 8'b00011001;
        else if (n64_reg_buttons[26] == 1'b1)
            o_led <= 8'b00011010;
        else if (n64_reg_buttons[27] == 1'b1)
            o_led <= 8'b00011011;
        else if (n64_reg_buttons[28] == 1'b1)
            o_led <= 8'b00011100;
        else if (n64_reg_buttons[29] == 1'b1)
            o_led <= 8'b00011101;
        else if (n64_reg_buttons[30] == 1'b1)
            o_led <= 8'b00011110;
        else if (n64_reg_buttons[31] == 1'b1)
            o_led <= 8'b00011111;
        else if (n64_reg_buttons[32] == 1'b1)
            o_led <= 8'b00100000;
        else if (n64_reg_buttons[33] == 1'b1)
            o_led <= 8'b00100001;
		end
	end


    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            rst_proc <= 1'b0;
        end else begin
            if (reset_reg_data[0] == 1'b0 && rst_proc && ~pico_axi_rready && ~pico_axi_bready)
                rst_proc <= 1'b0;
            else if (reset_reg_axi_bready && reset_reg_axi_bvalid) begin
                rst_proc <= reset_reg_data[0];
            end    
        end
    end
   // assign rst_proc = reset_reg_data[0];  
    
    
endmodule
