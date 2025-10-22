//RESEN

`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	sdram_ctrl_axi.v
//
// Project:	ArrowZip, a demonstration of the Arrow MAX1000 FPGA board
//
// Purpose:	Provide 32-bit AXI-Lite access to the SDRAM memory on a MAX1000
//		board. This is a modified version of the original wbsdram.v
//		that replaces Wishbone with AXI-Lite interface.
//
////////////////////////////////////////////////////////////////////////////////

`default_nettype none

`define DMOD_GETINPUT          1'b0
`define DMOD_PUTOUTPUT         1'b1
`define RAM_OPERATIONAL        2'b11
`define RAM_POWER_UP           2'b00
`define RAM_SET_MODE           2'b01
`define RAM_INITIAL_REFRESH    2'b10

module sdram_ctrl_axi #(
    parameter RDLY = 6,
    parameter NCA  = 8, 
    parameter NRA  = 12, 
    parameter AW   = (NCA+NRA+2)-1, 
    parameter DW   = 32,
    parameter [NCA-2:0] COL_THRESHOLD = -16
) (
    // Clock and reset
    input wire            sdram_axi_aclk,
    input wire            sdram_axi_aresetn,
    
    // AXI-Lite Interface
    // Write Address Channel
    input wire            sdram_axi_awvalid,
    output reg            sdram_axi_awready,
    input wire [AW-1:0]   sdram_axi_awaddr,
    
    // Write Data Channel
    input wire            sdram_axi_wvalid,
    output reg            sdram_axi_wready,
    input wire [DW-1:0]   sdram_axi_wdata,
    input wire [DW/8-1:0] sdram_axi_wstrb,
    
    // Write Response Channel
    output reg            sdram_axi_bvalid,
    input wire            sdram_axi_bready,
    
    // Read Address Channel
    input wire            sdram_axi_arvalid,
    output reg            sdram_axi_arready,
    input wire [AW-1:0]   sdram_axi_araddr,
    
    // Read Data Channel
    output reg            sdram_axi_rvalid,
    input wire            sdram_axi_rready,
    output reg [DW-1:0]   sdram_axi_rdata,
    
    // SDRAM control
    output reg            o_ram_cs_n,
    output wire           o_ram_cke,
    output reg            o_ram_ras_n, 
    output reg            o_ram_cas_n, 
    output reg            o_ram_we_n,
    output reg [ 1:0]     o_ram_bs,
    output reg [11:0]     o_ram_addr,
    output reg            o_ram_dmod,
    input wire [15:0]     i_ram_data,
    output reg [15:0]     o_ram_data,
    output reg [ 1:0]     o_ram_dqm,
    output wire [DW-1:0]  o_debug
);

    // Local declarations
    wire                need_refresh;
    reg  [9:0]          refresh_clk;
    wire                refresh_cmd;
    wire                in_refresh;
    reg  [2:0]          in_refresh_clk;
    reg  [2:0]          bank_active[0:3];
    reg  [(RDLY-1):0]   r_barrell_ack;
    reg                 r_pending;
    reg                 r_we;
    reg  [(AW-1):0]     r_addr;
    reg  [31:0]         r_data;
    reg  [3:0]          r_sel;
    reg  [(AW-NCA-2):0] bank_row[0:3];
    reg  [2:0]          clocks_til_idle;
    reg  [1:0]          m_state;
    wire                bus_cyc;
    reg                 nxt_dmod;
    wire                pending;
    reg  [(AW-1):0]     fwd_addr;
    wire [1:0]          wb_bs, r_bs, fwd_bs;
    wire [NRA-1:0]      wb_row, r_row, fwd_row;
    reg                 r_bank_valid;
    reg                 fwd_bank_valid;
    reg                 maintenance_mode;
    reg                 m_ram_cs_n, m_ram_ras_n, m_ram_cas_n, m_ram_we_n, m_ram_dmod;
    reg [(NRA-1):0]     m_ram_addr;
    reg                 startup_hold;
    reg [15:0]          startup_idle;
    reg [3:0]           maintenance_clocks;
    reg                 maintenance_clocks_zero;
    reg [15:0]          last_ram_data [0:4];
    reg                 word_sel;

    // AXI-Lite state machine states
    localparam [1:0] 
        IDLE       = 2'b00,
        READ_DATA  = 2'b01,
        WRITE_DATA = 2'b10,
        WRITE_RESP = 2'b11;

    reg [1:0] axi_state;
    reg [1:0] next_axi_state;

    // SDRAM state machine states
    localparam STATE_SIZE = 4;
    localparam 
        MAINTENANCE            = 0,
        NOOP                   = 1,
        CLOSE_ALL_ACTIVE_BANKS = 2,
        PRECHARGE_ALL          = 3,
        AUTO_REFRESH           = 4,
        IN_REFRESH             = 5,
        ACTIVATE               = 6,
        CLOSE_BANK             = 7,
        READ                   = 8,
        WRITE                  = 9,
        PRECHARGE              = 10,
        PRE_ACTIVATE           = 11;

    reg [STATE_SIZE-1:0] state;

    // AXI-Lite Interface Handling
    always @(posedge sdram_axi_aclk or negedge sdram_axi_aresetn) begin
        if (!sdram_axi_aresetn) begin
            axi_state <= IDLE;
            sdram_axi_awready <= 1'b0;
            sdram_axi_wready  <= 1'b0;
            sdram_axi_bvalid  <= 1'b0;
            sdram_axi_arready <= 1'b1;
            sdram_axi_rvalid  <= 1'b0;
        end else begin
            case (axi_state)
                IDLE: begin
                    sdram_axi_arready <= 1'b1;
                    
                    if (sdram_axi_arvalid && sdram_axi_arready) begin
                        // Read request
                        sdram_axi_arready <= 1'b0;
                        r_addr            <= sdram_axi_araddr;
                        r_we              <= 1'b0;
                        r_pending         <= 1'b1;
                        axi_state         <= READ_DATA;
                    end 
                    else if (sdram_axi_awvalid && sdram_axi_awready) begin
                        // Write address phase
                        sdram_axi_awready <= 1'b0;
                        r_addr            <= sdram_axi_awaddr;
                        r_we              <= 1'b1;
                        axi_state         <= WRITE_DATA;
                    end
                    else begin
                        sdram_axi_awready <= 1'b1;
                    end
                end
                
                READ_DATA: begin
                    if (r_barrell_ack[0]) begin
                        sdram_axi_rdata  <= { last_ram_data[0], last_ram_data[2] };
                        sdram_axi_rvalid <= 1'b1;
                        r_pending <= 1'b0;
                        
                        if (sdram_axi_rready) begin
                            sdram_axi_rvalid  <= 1'b0;
                            sdram_axi_arready <= 1'b1;
                            axi_state         <= IDLE;
                        end
                    end
                end
                
                WRITE_DATA: begin
                    sdram_axi_wready <= 1'b1;
                    
                    if (sdram_axi_wvalid && sdram_axi_wready) begin
                        sdram_axi_wready <= 1'b0;
                        r_data           <= sdram_axi_wdata;
                        r_sel            <= sdram_axi_wstrb;
                        r_pending        <= 1'b1;
                        axi_state        <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (r_barrell_ack[0]) begin
                        sdram_axi_bvalid <= 1'b1;
                        r_pending        <= 1'b0;
                        
                        if (sdram_axi_bready) begin
                            sdram_axi_bvalid  <= 1'b0;
                            sdram_axi_awready <= 1'b1;
                            axi_state         <= IDLE;
                        end
                    end
                end
            endcase
        end
    end

    // Refresh logic (unchanged from original)
    assign refresh_cmd = (!o_ram_cs_n)&&(!o_ram_ras_n)&&(!o_ram_cas_n)&&(o_ram_we_n);

    initial refresh_clk = 0;
    always @(posedge sdram_axi_aclk) begin
        if (refresh_cmd)
            refresh_clk <= 10'd391;
        else if (|refresh_clk)
            refresh_clk <= refresh_clk - 10'h1;
    end

    assign need_refresh = (refresh_clk == 10'h00)&&(!refresh_cmd);

    initial in_refresh_clk = 3'h0;
    always @(posedge sdram_axi_aclk) begin
        if (refresh_cmd)
            in_refresh_clk <= 3'h6;
        else if (|in_refresh_clk)
            in_refresh_clk <= in_refresh_clk - 3'h1;
    end

    assign in_refresh = (in_refresh_clk != 3'h0)||(refresh_cmd);

    // SDRAM control logic (mostly unchanged from original)
    assign bus_cyc = (r_pending);

    assign wb_bs   = r_addr[NCA:NCA-1];
    assign r_bs    = r_addr[NCA:NCA-1];
    assign fwd_bs  = fwd_addr[NCA:NCA-1];

    assign wb_row  = r_addr[AW-1:NCA+1];
    assign r_row   = r_addr[AW-1:NCA+1];
    assign fwd_row = fwd_addr[AW-1:NCA+1];

    // r_bank_valid
    initial r_bank_valid = 1'b0;
    always @(posedge sdram_axi_aclk) begin
        if (bus_cyc)
            r_bank_valid <= ((bank_active[wb_bs][2]) && (bank_row[wb_bs] == wb_row));
        else
            r_bank_valid <= ((bank_active[r_bs][2]) && (bank_row[r_bs] == r_row));
    end

    // fwd_bank_valid
    initial fwd_bank_valid = 0;
    always @(posedge sdram_axi_aclk) begin
        fwd_bank_valid <= ((bank_active[fwd_bs][2]) && (bank_row[fwd_bs] == fwd_row));
    end

    assign pending = (r_pending);

    // SDRAM state machine (similar to original but adapted for AXI)
    initial r_barrell_ack   = 0;
    initial clocks_til_idle = 3'h0;
    initial o_ram_dmod      = `DMOD_GETINPUT;
    initial nxt_dmod        = `DMOD_GETINPUT;
    initial o_ram_cs_n      = 1'b0;
    initial o_ram_ras_n     = 1'b1;
    initial o_ram_cas_n     = 1'b1;
    initial o_ram_we_n      = 1'b1;
    initial o_ram_dqm       = 2'b11;
    assign o_ram_cke        = 1'b1;
    initial bank_active[0]  = 3'b000;
    initial bank_active[1]  = 3'b000;
    initial bank_active[2]  = 3'b000;
    initial bank_active[3]  = 3'b000;
    initial word_sel = 0;

    always @(posedge sdram_axi_aclk) begin
        if (maintenance_mode) begin
            state = MAINTENANCE;
            bank_active[0]            <= 0;
            bank_active[1]            <= 0;
            bank_active[2]            <= 0;
            bank_active[3]            <= 0;
            r_barrell_ack[(RDLY-1):0] <= 0;
            o_ram_cs_n                <= m_ram_cs_n;
            o_ram_ras_n               <= m_ram_ras_n;
            o_ram_cas_n               <= m_ram_cas_n;
            o_ram_we_n                <= m_ram_we_n;
            o_ram_dmod                <= m_ram_dmod;
            o_ram_addr                <= m_ram_addr;
            o_ram_bs                  <= 2'b00;
            nxt_dmod                  <= `DMOD_GETINPUT;
        end else begin
            state = NOOP;
            if (!sdram_axi_aresetn)
                r_barrell_ack <= 0;
            else
                r_barrell_ack <= r_barrell_ack >> 1;
                
            nxt_dmod   <= `DMOD_GETINPUT;
            o_ram_dmod <= nxt_dmod;

            bank_active[0] <= { bank_active[0][2], bank_active[0][2:1] };
            bank_active[1] <= { bank_active[1][2], bank_active[1][2:1] };
            bank_active[2] <= { bank_active[2][2], bank_active[2][2:1] };
            bank_active[3] <= { bank_active[3][2], bank_active[3][2:1] };
            
            o_ram_cs_n <= (!r_pending);
            
            if (|clocks_til_idle[2:0])
                clocks_til_idle[2:0] <= clocks_til_idle[2:0] - 3'h1;

            o_ram_ras_n <= 1'b1;
            o_ram_cas_n <= 1'b1;
            o_ram_we_n  <= 1'b1;

            if (nxt_dmod)
                state = NOOP;
            else if (in_refresh) begin
                state = IN_REFRESH;
            end else if ((pending)&&(!r_bank_valid)&&(bank_active[r_bs]==3'h0)&&(!in_refresh) && (state != IN_REFRESH)) begin
                // Need to activate the requested bank
                state                 = ACTIVATE;
                o_ram_cs_n           <= 1'b0;
                o_ram_ras_n          <= 1'b0;
                o_ram_cas_n          <= 1'b1;
                o_ram_we_n           <= 1'b1;
                o_ram_addr           <= r_row;
                o_ram_bs             <= r_bs;
                bank_active[r_bs][2] <= 1'b1;
                bank_row[r_bs]       <= r_row;
                word_sel             <= 1'b0;
            end else if ((pending)&&(!r_bank_valid) && (bank_active[r_bs]==3'b111)) begin
                // Need to close an active bank
                state                 = CLOSE_BANK;
                o_ram_cs_n           <= 1'b0;
                o_ram_ras_n          <= 1'b0;
                o_ram_cas_n          <= 1'b1;
                o_ram_we_n           <= 1'b0;
                o_ram_addr[10]       <= 1'b0;
                o_ram_bs             <= r_bs;
                bank_active[r_bs][2] <= 1'b0;
            end else if ((pending)&&(!r_we) && (bank_active[r_bs][2]) && (r_bank_valid) && (clocks_til_idle[2:0] < 4)) begin
                // Issue the read command
                state                    = READ;
                o_ram_cs_n              <= 1'b0;
                o_ram_ras_n             <= 1'b1;
                o_ram_cas_n             <= 1'b0;
                o_ram_we_n              <= 1'b1;
                o_ram_addr              <= { 4'h0, r_addr[NCA-2:0], word_sel };
                o_ram_bs                <= r_bs;
                clocks_til_idle[2:0]    <= 4;
                r_barrell_ack[(RDLY-1)] <= 1'b1;
                word_sel                <= !word_sel;
            end else if ((pending)&&(r_we) && (bank_active[r_bs][2]) && (r_bank_valid) && (clocks_til_idle[2:0] == 0)) begin
                // Issue the write command
                state                 = WRITE;
                o_ram_cs_n           <= 1'b0;
                o_ram_ras_n          <= 1'b1;
                o_ram_cas_n          <= 1'b0;
                o_ram_we_n           <= 1'b0;
                o_ram_addr           <= { 4'h0, r_addr[NCA-2:0], word_sel };
                o_ram_bs             <= r_bs;
                clocks_til_idle[2:0] <= 3'h1;
                r_barrell_ack[1]     <= 1'b1;
                o_ram_dmod           <= `DMOD_PUTOUTPUT;
                nxt_dmod             <= `DMOD_PUTOUTPUT;
                word_sel             <= !word_sel;
            end else if ((r_pending)&&(r_addr[(NCA-2):0] >= COL_THRESHOLD) && (!fwd_bank_valid)) begin
                // Do I need to close the next bank I'll need?
                if (bank_active[fwd_bs][2:1]==2'b11) begin
                    // Need to close the bank first
                    state                   = PRECHARGE;
                    o_ram_cs_n             <= 1'b0;
                    o_ram_ras_n            <= 1'b0;
                    o_ram_cas_n            <= 1'b1;
                    o_ram_we_n             <= 1'b0;
                    o_ram_addr[10]         <= 1'b0;
                    o_ram_bs               <= fwd_bs;
                    bank_active[fwd_bs][2] <= 1'b0;
                end else if (bank_active[fwd_bs]==0) begin
                    // Need to (pre-)activate the next bank
                    state                = PRE_ACTIVATE;
                    o_ram_cs_n          <= 1'b0;
                    o_ram_ras_n         <= 1'b0;
                    o_ram_cas_n         <= 1'b1;
                    o_ram_we_n          <= 1'b1;
                    o_ram_addr          <= fwd_row;
                    o_ram_bs            <= fwd_bs;
                    bank_active[fwd_bs] <= 3'h4;
                    bank_row[fwd_bs]    <= fwd_row;
                end
            end else if ((!r_pending)||(need_refresh)) begin
                // Issue a precharge all command (if any banks are open),
                // otherwise an autorefresh command
                if ((bank_active[0][2:1]==2'b10)     || (bank_active[1][2:1]==2'b10)    || 
                    (bank_active[2][2:1]==2'b10)     || (bank_active[3][2:1]==2'b10)    ||
                    (|clocks_til_idle[2:0])          || (bank_active[0]     == 3'b110)  || 
                    (bank_active[1]     == 3'b110)   || (bank_active[2]     == 3'b110)  || 
                    (bank_active[3]     == 3'b110)) begin
                    // Do nothing this clock
                    state = NOOP;
                end else if (bank_active[0][2] || bank_active[1][2] || 
                           bank_active[2][2]   || bank_active[3][2]) begin
                    // Close all active banks
                    state              = PRECHARGE_ALL;
                    o_ram_cs_n        <= 1'b0;
                    o_ram_ras_n       <= 1'b0;
                    o_ram_cas_n       <= 1'b1;
                    o_ram_we_n        <= 1'b0;
                    o_ram_addr[10]    <= 1'b1;
                    bank_active[0][2] <= 1'b0;
                    bank_active[1][2] <= 1'b0;
                    bank_active[2][2] <= 1'b0;
                    bank_active[3][2] <= 1'b0;
                end else if ((|bank_active[0]) || (|bank_active[1]) || 
                            (|bank_active[2])  || (|bank_active[3])) begin
                    // Can't precharge yet, the bus is still busy
                end else if (need_refresh && r_barrell_ack == 0) begin
                    // Send autorefresh command
                    state        = AUTO_REFRESH;
                    o_ram_cs_n  <= 1'b0;
                    o_ram_ras_n <= 1'b0;
                    o_ram_cas_n <= 1'b0;
                    o_ram_we_n  <= 1'b1;
                end
            end
            
            if (!r_pending)
                r_barrell_ack <= 0;
        end
    end

    // Startup and maintenance logic (unchanged from original)
    initial startup_idle = 16'd20500;
    initial startup_hold = 1'b1;
    always @(posedge sdram_axi_aclk) begin
        if (|startup_idle)
            startup_idle <= startup_idle - 1'b1;
    end

    always @(posedge sdram_axi_aclk) begin
        startup_hold <= |startup_idle;
    end

    initial maintenance_mode        = 1'b1;
    initial maintenance_clocks      = 4'hf;
    initial maintenance_clocks_zero = 1'b0;
    initial m_ram_addr              = { 2'b00, 1'b0, 2'b00, 3'b011, 1'b0, 3'b000 };
    initial m_state                 = `RAM_POWER_UP;
    initial m_ram_cs_n              = 1'b1;
    initial m_ram_ras_n             = 1'b1;
    initial m_ram_cas_n             = 1'b1;
    initial m_ram_we_n              = 1'b1;
    initial m_ram_dmod              = `DMOD_GETINPUT;

    always @(posedge sdram_axi_aclk) begin
        if (!maintenance_clocks_zero) begin 
            maintenance_clocks      <= maintenance_clocks - 4'h1;
            maintenance_clocks_zero <= (maintenance_clocks == 4'h1);
        end
        
        m_ram_addr <= { 2'b00, 1'b0, 2'b00, 3'b011, 1'b0, 3'b000 };
        
        if (m_state == `RAM_POWER_UP) begin
            m_ram_cs_n  <= 1'b1;
            m_ram_ras_n <= 1'b1;
            m_ram_cas_n <= 1'b1;
            m_ram_we_n  <= 1'b1;
            m_ram_dmod  <= `DMOD_GETINPUT;
            
            if (!startup_hold) begin
                m_state                 <= `RAM_INITIAL_REFRESH;
                maintenance_clocks      <= 4'hc;
                maintenance_clocks_zero <= 1'b0;
                m_ram_cs_n              <= 1'b0;
                m_ram_ras_n             <= 1'b0;
                m_ram_cas_n             <= 1'b1;
                m_ram_we_n              <= 1'b0;
                m_ram_addr[10]          <= 1'b1;
            end
        end else if (m_state == `RAM_INITIAL_REFRESH) begin
            m_ram_cs_n  <= 1'b0;
            m_ram_ras_n <= 1'b1;
            m_ram_cas_n <= 1'b1;
            m_ram_we_n  <= 1'b1;
            
            if (maintenance_clocks == 4'hb || maintenance_clocks == 4'h5) begin
                m_ram_cs_n  <= 1'b0;
                m_ram_ras_n <= 1'b0;
                m_ram_cas_n <= 1'b0;
                m_ram_we_n  <= 1'b1;
            end else begin
                m_ram_cs_n  <= 1'b0;
                m_ram_ras_n <= 1'b1;
                m_ram_cas_n <= 1'b1;
                m_ram_we_n  <= 1'b1;
            end
            
            m_ram_dmod  <= `DMOD_GETINPUT;
            
            if (maintenance_clocks_zero) begin
                m_state <= `RAM_SET_MODE;
            end
        end else if (m_state == `RAM_SET_MODE) begin
            if (maintenance_clocks_zero) begin
                m_ram_cs_n     <= 1'b0;
                m_ram_ras_n    <= 1'b0;
                m_ram_cas_n    <= 1'b0;
                m_ram_we_n     <= 1'b0;
                m_ram_dmod     <= `DMOD_GETINPUT;
                m_ram_addr[10] <= 1'b0;
                
                if (maintenance_clocks_zero)
                    m_state <= `RAM_OPERATIONAL;
            end
        end else if (m_state == `RAM_OPERATIONAL) begin
            maintenance_clocks_zero <= 1'b0;
            if (maintenance_clocks_zero) begin
                maintenance_mode        <= 1'b0;
                maintenance_clocks_zero <= 1'b1;
            end
        end
    end

    // Data handling
    always @(posedge sdram_axi_aclk) begin
        if (!word_sel)
            o_ram_data <= r_data[15:0];
        else
            o_ram_data <= r_data[31:16];
    end

    always @(posedge sdram_axi_aclk) begin
        if (maintenance_mode)
            o_ram_dqm <= 2'b11;
        else if (r_we) begin
            if (!word_sel)
                o_ram_dqm <= ~r_sel[1:0];
            else
                o_ram_dqm <= ~r_sel[3:2];
        end else begin
            o_ram_dqm <= 2'b00;
        end
    end

    always @(posedge sdram_axi_aclk) begin
        last_ram_data[0] <= i_ram_data;
        last_ram_data[1] <= last_ram_data[0];
        last_ram_data[2] <= last_ram_data[1];
        last_ram_data[3] <= last_ram_data[2]; 
        last_ram_data[4] <= last_ram_data[3];        
    end

    // Debug output (unchanged from original)
    reg trigger;
    always @(posedge sdram_axi_aclk) begin
        trigger <= ((sdram_axi_rdata[15:0]==sdram_axi_rdata[31:16]) && (sdram_axi_rvalid) && (!r_we));
    end

    assign o_debug = { 
        (axi_state != IDLE), (r_pending), r_we, (axi_state == READ_DATA), (axi_state == WRITE_DATA), // 5
        o_ram_cs_n, o_ram_ras_n, o_ram_cas_n, o_ram_we_n, o_ram_bs, // 6
        o_ram_dmod, r_pending, // 2
        trigger, // 1
        o_ram_addr[9:0], // 10 more
        (r_we) ? { o_ram_data[7:0] } : { sdram_axi_rdata[23:20], sdram_axi_rdata[3:0] } // 8 values
    };

endmodule
