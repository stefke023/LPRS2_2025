//RESEN

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/23/2025 03:23:24 PM
// Design Name: 
// Module Name: uart_axi
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


module uart_axi #(
    parameter CLK_FREQ  = 12000000,
    parameter BAUD_RATE = 115200

    )(

    input wire        clk, 
    input wire        resetn,
	//output trap,

	// AXI4-lite master memory interface

	output wire        uart_axi_awvalid,
	input  wire        uart_axi_awready,
	output wire [31:0] uart_axi_awaddr,
	output wire [ 2:0] uart_axi_awprot,

	output wire        uart_axi_wvalid,
	input  wire        uart_axi_wready,
	output wire [31:0] uart_axi_wdata,
	output wire [ 3:0] uart_axi_wstrb,

	input wire         uart_axi_bvalid,
	output wire        uart_axi_bready,
	input wire  [ 1:0] uart_axi_bresp,

	output wire        uart_axi_arvalid,
	input  wire        uart_axi_arready,
	output wire [31:0] uart_axi_araddr,
	output wire [ 2:0] uart_axi_arprot,

	input  wire        uart_axi_rvalid,
	output wire        uart_axi_rready,
	input  wire [ 1:0] uart_axi_rresp,
	input  wire [31:0] uart_axi_rdata,
	
	// UART interface
	
	input  wire       i_serial_rx,
	output wire       o_serial_tx,
	output wire       on_serial_cts,
	output wire       on_serial_dsr
    );
    
    wire  [ 7:0] s_uart_rx_data;//      : in  std_logic_vector(7 downto 0);
    wire         s_uart_rx_valid;//      : in  std_logic;
    wire  [ 7:0] s_uart_tx_data;//   : out std_logic_vector(7 downto 0);
    wire         s_uart_tx_valid;//    : out std_logic;
    wire         s_uart_tx_busy;
    
    uart_rx_tx #(
        .CLK_FREQ        (CLK_FREQ          ),
        .BAUD_RATE       (BAUD_RATE         )
        ) uart  (
		.i_clk           (clk               ), 
		.in_rst          (resetn            ),
		
		.i_serial_rx     (i_serial_rx       ),
		.o_serial_tx     (o_serial_tx       ),
		.on_serial_cts   (on_serial_cts     ),
		.on_serial_dsr   (on_serial_dsr     ),
		
		.i_byte_tx_data  (s_uart_tx_data    ),//1
		.i_byte_tx_valid (s_uart_tx_valid   ),//2
		.o_byte_tx_busy  (s_uart_tx_busy    ),//3
		.o_byte_rx_data  (s_uart_rx_data    ),//4
		.o_byte_rx_valid (s_uart_rx_valid   )//5
	);
	
	/*uart_axi_adapter axi_adapter ( */
	/*uart_axi_dma #(.MAGIC_WORD(16'hBEEF)) dma(*/
	uart_axi_adapter dma (
	    .i_clk           (clk               ),
        .i_rstn          (resetn            ),

        .i_uart_rx_data  (s_uart_rx_data    ),
        .i_uart_rx_valid (s_uart_rx_valid   ),
        .o_uart_tx_data  (s_uart_tx_data    ),
        .o_uart_tx_valid (s_uart_tx_valid   ),
        .i_uart_tx_busy  (s_uart_tx_busy    ),

        .o_axi_awaddr    (uart_axi_awaddr    ),
        .o_axi_awvalid   (uart_axi_awvalid   ),
        .o_axi_awprot    (uart_axi_awprot    ),
        .i_axi_awready   (uart_axi_awready   ),
        .o_axi_wdata     (uart_axi_wdata     ),
        .o_axi_wstrb     (uart_axi_wstrb     ),
        .o_axi_wvalid    (uart_axi_wvalid    ),
        .i_axi_wready    (uart_axi_wready    ),
		.i_axi_bresp     (uart_axi_bresp     ),
        .i_axi_bvalid    (uart_axi_bvalid    ),
        .o_axi_bready    (uart_axi_bready    ),
        .o_axi_araddr    (uart_axi_araddr    ),
        .o_axi_arvalid   (uart_axi_arvalid   ),
        .o_axi_arprot    (uart_axi_arprot    ),
        .i_axi_arready   (uart_axi_arready   ),
        .i_axi_rdata     (uart_axi_rdata     ),
		.i_axi_rresp     (uart_axi_rresp     ),
        .i_axi_rvalid    (uart_axi_rvalid    ),
        .o_axi_rready    (uart_axi_rready    )
	);
endmodule
