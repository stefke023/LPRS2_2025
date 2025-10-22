//RESEN

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/30/2025 04:26:06 PM
// Design Name: 
// Module Name: mmreg_axi
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


module mmreg_axi #( 
    parameter TARG_ADDR = 32'h00000100,
    parameter IS_RST_REG = 1'b0
    
    )(
    // Global signals
    input       mmreg_axi_aclk,
    input       mmreg_axi_aresetn,
    
    // Write Address Channel
    input [31:0]      mmreg_axi_awaddr,
    input             mmreg_axi_awvalid,
    output reg        mmreg_axi_awready,
     
    // Write Data Channel
    input [31:0]      mmreg_axi_wdata,
    input [ 3:0]      mmreg_axi_wstrb,
    input             mmreg_axi_wvalid,
    output reg        mmreg_axi_wready,
    
    // Write Response Channel
    output reg [1:0]  mmreg_axi_bresp,
    output reg        mmreg_axi_bvalid,
    input             mmreg_axi_bready,
    
    // Read Address Channel
    input [31:0]      mmreg_axi_araddr,
    input             mmreg_axi_arvalid,
    output reg        mmreg_axi_arready,
    
    // Read Data Channel
    output reg [31:0] mmreg_axi_rdata,
    output reg [ 1:0] mmreg_axi_rresp,
    output reg        mmreg_axi_rvalid,
    input             mmreg_axi_rready,

    output     [31:0] mmreg_out_data
);

    // Internal registers
    reg [31:0] mmreg_data;
    reg        mmreg_valid;

    // Write Address Ready generation
    always @(posedge mmreg_axi_aclk) begin
        if (mmreg_axi_aresetn == 1'b0) begin
            mmreg_axi_awready <= 1'b0;
        end else begin    
            if (!mmreg_axi_awready && mmreg_axi_awvalid) begin
                mmreg_axi_awready <= 1'b1;
            end else if (mmreg_axi_awready) begin
                mmreg_axi_awready <= 1'b0;    
            end else if (mmreg_axi_bvalid) begin
            end
        end 
    end

    // Write Data Ready generation
    always @(posedge mmreg_axi_aclk) begin
        if (mmreg_axi_aresetn == 1'b0) begin
            mmreg_axi_wready <= 1'b0;
            mmreg_valid      <= 1'b0;
            if (IS_RST_REG)
                mmreg_data <= 0;
            else
                mmreg_data <= 32'h00000081; // default value for LED register
        end else begin    
            if (!mmreg_axi_wready && mmreg_axi_wvalid) begin
                mmreg_valid      <= 1'b1;
                mmreg_axi_wready <= 1'b1;
                if (mmreg_axi_awaddr == TARG_ADDR) begin
                    if(mmreg_axi_wstrb[3]) mmreg_data[31:24] <= mmreg_axi_wdata[31:24];
			        if(mmreg_axi_wstrb[2]) mmreg_data[23:16] <= mmreg_axi_wdata[23:16];	
			        if(mmreg_axi_wstrb[1]) mmreg_data[15: 8] <= mmreg_axi_wdata[15: 8];
			        if(mmreg_axi_wstrb[0]) mmreg_data[ 7: 0] <= mmreg_axi_wdata[ 7: 0];
                end
            end else if (mmreg_axi_wready) begin
                mmreg_axi_wready <= 1'b0;
                mmreg_valid      <= 1'b0;
            end
        end 
    end

    // Write Response generation
    always @(posedge mmreg_axi_aclk) begin
        if (mmreg_axi_aresetn == 1'b0) begin
            mmreg_axi_bvalid <= 1'b0;
            mmreg_axi_bresp  <= 2'b11; // NOT_OKAY response by default
        end else begin    
            if (!mmreg_axi_bvalid && mmreg_valid) begin
                mmreg_axi_bvalid <= 1'b1;
                mmreg_axi_bresp  <= 2'b00; // OKAY response
            end else begin
                if (mmreg_axi_bvalid && mmreg_axi_bready) begin
                    mmreg_axi_bvalid <= 1'b0;
                    mmreg_axi_bresp  <= 2'b11;
                end
            end
        end
    end

    // Read Address Ready generation
    always @(posedge mmreg_axi_aclk) begin
        if (mmreg_axi_aresetn == 1'b0) begin
            mmreg_axi_arready <= 1'b0;
        end else begin    
            if (!mmreg_axi_arready && mmreg_axi_arvalid) begin
                mmreg_axi_arready <= 1'b1;
            end else begin
                mmreg_axi_arready <= 1'b0;
            end
        end 
    end

    // Read Data Valid generation
    always @(posedge mmreg_axi_aclk) begin
        if (mmreg_axi_aresetn == 1'b0) begin
            mmreg_axi_rvalid <= 1'b0;
            mmreg_axi_rdata  <= 0;
            mmreg_axi_rresp  <= 2'b11; // NOT_OKAY response by default
        end else begin    
            if (mmreg_axi_rready && !mmreg_axi_rvalid) begin
                mmreg_axi_rvalid <= 1'b1;
                 if (mmreg_axi_araddr == TARG_ADDR) begin
                    mmreg_axi_rdata <= mmreg_data;
                    mmreg_axi_rresp <= 2'b00; // OKAY response
                end
            end else if (mmreg_axi_rvalid ) begin
                mmreg_axi_rvalid <= 1'b0;
                mmreg_axi_rdata  <= 0;
                mmreg_axi_rresp  <= 2'b11;
            end
        end
    end
    assign mmreg_out_data = mmreg_data;
    
endmodule
