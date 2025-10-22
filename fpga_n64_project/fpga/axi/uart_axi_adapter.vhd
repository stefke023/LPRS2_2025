--RESEN

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_axi_adapter is
    Port ( 
        -- On MAX1000.
		-- System signals.
		i_clk                :  in std_logic;
		i_rstn               :  in std_logic; -- Active low reset.
		
		-- UART Bridge Interface
        i_uart_rx_data       : in  std_logic_vector(7 downto 0);
        i_uart_rx_valid      : in  std_logic;
        o_uart_tx_data       : out std_logic_vector(7 downto 0);
        o_uart_tx_valid      : out std_logic;
        i_uart_tx_busy       : in  std_logic;
		
		-- AXI Lite Master Interface
        -- Write Address Channel
        o_axi_awaddr         : out std_logic_vector(31 downto 0);
        o_axi_awvalid        : out std_logic;
        o_axi_awprot         : out std_logic_vector(2 downto 0);
        i_axi_awready        : in  std_logic;
        
        -- Write Data Channel
        o_axi_wdata          : out std_logic_vector(31 downto 0);
        o_axi_wstrb          : out std_logic_vector(3 downto 0);
        o_axi_wvalid         : out std_logic;
        i_axi_wready         : in  std_logic;
        
        -- Write Response Channel
        i_axi_bresp          : in  std_logic_vector(1 downto 0);
        i_axi_bvalid         : in  std_logic;
        o_axi_bready         : out std_logic;
        
        -- Read Address Channel
        o_axi_araddr         : out std_logic_vector(31 downto 0);
        o_axi_arvalid        : out std_logic;
        o_axi_arprot         : out std_logic_vector(2 downto 0);
        i_axi_arready        : in  std_logic;
        
        -- Read Data Channel
        i_axi_rdata          : in  std_logic_vector(31 downto 0);
        i_axi_rresp          : in  std_logic_vector(1 downto 0);
        i_axi_rvalid         : in  std_logic;
        o_axi_rready         : out std_logic
    );
end uart_axi_adapter;

architecture rtl of uart_axi_adapter is
    type state_t is (IDLE, CMD, DATA_SIZE, ADDR, DATA, WRITE, READ, RESPONSE, SEND_BYTES);
    signal state_reg   : state_t := IDLE;
    signal state_next  : state_t;
    
    signal cmd_reg, cmd_next               : std_logic_vector( 7 downto 0);
    signal size_reg, size_next             : std_logic_vector(23 downto 0);
    signal rem_size_reg, rem_size_next     : unsigned(23 downto 0);
    signal addr_reg, addr_next             : std_logic_vector(31 downto 0);
    signal curr_addr_reg, curr_addr_next   : std_logic_vector(31 downto 0);
    signal data_reg , data_next            : std_logic_vector(31 downto 0);
    signal tmp_data_reg, tmp_data_next     : std_logic_vector(31 downto 0);
    signal byte_cnt_reg, byte_cnt_next     : integer range 0 to 4;     
    --signal has_more_data

    --constant BRAM_ADDR_OFSET       : std_logic_vector(31 downto 0):= x"1000";
    --constant SDRAM_ADDR_OFSET      : std_logic_vector(31 downto 0):= x"2000";
    --constant LED_ADDR_OFSET        : std_logic_vector(31 downto 0):= x"4000";
    --constant CAN_IP_ADDR_OFSET     : std_logic_vector(31 downto 0):= x"8000";
begin
    seq_logic: process(i_clk, i_rstn)
    begin
        if i_rstn = '0' then
            state_reg     <= IDLE ;
            cmd_reg       <= (others => '0');
            size_reg      <= (others => '0');
            rem_size_reg  <= (others => '0');
            addr_reg      <= (others => '0');
            curr_addr_reg <= (others => '0');
            data_reg      <= (others => '0');
            tmp_data_reg  <= (others => '0');
            byte_cnt_reg  <= 0;
            
        elsif rising_edge(i_clk) then
            state_reg     <= state_next;
            cmd_reg       <= cmd_next;
            size_reg      <= size_next;
            rem_size_reg  <= rem_size_next;
            addr_reg      <= addr_next;
            curr_addr_reg <= curr_addr_next;
            data_reg      <= data_next;
            tmp_data_reg  <= tmp_data_next;
            byte_cnt_reg  <= byte_cnt_next;
                    
        end if;
    end process;
    
    comb_logic: process(state_reg, cmd_reg, size_reg, rem_size_reg, addr_reg, curr_addr_reg, data_reg, tmp_data_reg, byte_cnt_reg,  i_uart_rx_data, i_uart_rx_valid, i_uart_tx_busy, i_axi_awready, i_axi_wready, i_axi_arready, i_axi_bvalid, i_axi_rvalid, i_axi_rdata)
    begin
        o_uart_tx_valid <= '0';
        o_axi_awvalid   <= '0';
        o_axi_wvalid    <= '0';
        o_axi_arvalid   <= '0';
        o_axi_bready    <= '0';
        o_axi_rready    <= '0';
        o_uart_tx_data  <= (others => '0');
        o_axi_awaddr    <= (others => '0');
        o_axi_wdata     <= (others => '0');  
        o_axi_wstrb     <= (others => '0'); 
        o_axi_araddr    <= (others => '0');
        cmd_next        <= cmd_reg;
        size_next       <= size_reg;
        rem_size_next   <= rem_size_reg;
        addr_next       <= addr_reg;
        curr_addr_next  <= curr_addr_reg;
        data_next       <= data_reg;
        tmp_data_next   <= tmp_data_reg;
        byte_cnt_next   <= byte_cnt_reg;
        
        case state_reg is 
            when IDLE =>
                if i_uart_rx_valid = '1' then
                    cmd_next   <= i_uart_rx_data;
                    state_next <= CMD;
                else
                    state_next <= IDLE;    
                end if;
                
            when CMD  =>  
                if cmd_reg(7 downto 6) = "10" or cmd_reg(7 downto 6) = "01" then
                    if i_uart_rx_valid = '1'  then
                        -- First byte of data size
                        size_next(23 downto 16) <= i_uart_rx_data;
                        byte_cnt_next           <= byte_cnt_reg + 1;
                        state_next              <= DATA_SIZE;
                    else
                        state_next <= CMD;    
                    end if;
                else
                    state_next <= IDLE; --Wrong command
                end if;    
                
            when DATA_SIZE => --Dodaj logiku za wstrb da ti za 4 bude f za 3 7 za 2 3 i za 1 1
                if i_uart_rx_valid = '1' then
                    if byte_cnt_reg = 3 then
                        byte_cnt_next           <= 0;
                        addr_next(31 downto 24) <= i_uart_rx_data;
                        state_next              <= ADDR;    
                    else
                        size_next  <= i_uart_rx_data & size_reg(23 downto 8); -- Next address byte
                        byte_cnt_next <= byte_cnt_reg + 1;
                        state_next    <= DATA_SIZE; 
                    end if;
                 else   
                    state_next <= DATA_SIZE; -- Wait for uart_rx_valid = '1'
                 end if;
                    
            when ADDR =>
                if i_uart_rx_valid = '1' then
                    if byte_cnt_reg = 3 then
                        if cmd_reg(7 downto 6) = "10" then -- Write command
                            tmp_data_next(31 downto 24) <= i_uart_rx_data;
                            byte_cnt_next <= 0;
                            rem_size_next <= unsigned(size_reg) - 4; -- Remaining size for write
                            curr_addr_next <= addr_reg; -- Set current address
                            state_next    <= DATA; 
                        elsif cmd_reg(7 downto 6) = "01" then -- Read command
                            byte_cnt_next <= 0;
                            state_next <= READ;                     
                        else
                            state_next <= IDLE; -- Unknown command return to IDLE    
                        end if;
                    else
                        addr_next <= i_uart_rx_data & addr_reg(31 downto 8); -- Next address byte
                        byte_cnt_next <= byte_cnt_reg + 1;
                        state_next    <= ADDR; 
                    end if;
                else
                    if byte_cnt_reg = 3 and cmd_reg(7 downto 6) = "01" then -- Read command
                        state_next <= READ;
                    else
                        state_next <= ADDR; -- Wait for uart_rx_valid = '1'
                    end if;    
                 end if;    
            
            when DATA =>
                if i_uart_rx_valid = '1' then
                    tmp_data_next  <= i_uart_rx_data & tmp_data_reg(31 downto 8);
                    if (byte_cnt_reg = 3  and (rem_size_reg = (unsigned(size_reg) - 1))) or (byte_cnt_reg = 4 and rem_size_reg > 0)  then
                        data_next       <= tmp_data_reg;
                        byte_cnt_next   <= 0;
                        state_next      <= WRITE;  
                    else
                        byte_cnt_next <= byte_cnt_reg + 1;
                        state_next  <= DATA;
                    end if;
                else
                    if (byte_cnt_reg = 3  and (rem_size_reg = (unsigned(size_reg) - 1))) or (byte_cnt_reg = 4 and rem_size_reg > 0)  then
                        data_next       <= tmp_data_reg;
                        state_next      <= WRITE;
                    else
                        state_next  <= DATA; 
                    end if;           
                end if;
                
            when WRITE =>
                o_axi_awaddr  <= curr_addr_reg;       
                
                o_axi_wdata   <= data_reg;
                o_axi_wstrb   <= "1111"; -- Assuming 4-byte write, all bytes are valid
                o_axi_wvalid  <= '1';
                o_axi_bready  <= '1'; 

                if i_axi_awready = '0' and i_axi_wready = '1' then
                    --o_axi_bready  <= '1';
                    byte_cnt_next <= 0;        
                    o_axi_awvalid  <= '0';
                    state_next    <= RESPONSE;
                else
                    o_axi_awvalid <= '1';
                    state_next    <= WRITE;    
                end if;
                    
             when READ =>
                o_axi_arvalid <= '1';
                o_axi_araddr  <= addr_reg;
                o_axi_rready  <= '1';    
                
                if i_axi_arready = '1' then 
                    --o_axi_rready  <= '1';   
                    byte_cnt_next <= 0;        
                    state_next    <= RESPONSE;
                else   
                    state_next    <= READ; 
                end if;
            
             when RESPONSE =>
                if (cmd_reg(7 downto 6) = "10" and i_axi_bvalid = '1') or 
                    (cmd_reg(7 downto 6) = "01" and i_axi_rvalid = '1') then
                    --o_axi_bready  <= '1';
                    --o_axi_rready  <= '1';
                    
                        if cmd_reg(7 downto 6) = "01" then -- Read response
                            o_axi_rready    <= '1';
                            data_next       <= i_axi_rdata; -- Capture read data
                            state_next     <= SEND_BYTES; -- Send bytes via UART
                        else
                            o_axi_bready    <= '1';
                            if rem_size_reg > 0 then
                                curr_addr_next <= std_logic_vector(unsigned(curr_addr_reg) + 4); -- Increment address for next write
                                rem_size_next <= rem_size_reg - 4; -- Decrement remaining size
                                state_next <= DATA; -- Continue sending data
                            else
                                state_next <= IDLE; -- Write complete, return to IDLE
                            end if;
                            --byte_cnt_next <= 0; -- Reset byte counter for next command
                            data_next <= (others => '0'); -- Clear data register
                        end if;
                        
                else
                    if cmd_reg(7 downto 6) = "10" then
                        o_axi_bready <= '1'; -- Wait for write response
                    else
                        o_axi_rready <= '1'; -- Wait for read response
                    end if;           
                    state_next  <= RESPONSE; -- Wait for valid response      
                end if;

             when SEND_BYTES =>
                if i_uart_tx_busy = '0' then
                    if cmd_reg(7 downto 6) = "10" then
                        --o_uart_tx_data <= data_reg(7 + byte_cnt_reg * 8 downto byte_cnt_reg * 8); -- Write command no response

                    else
                        o_uart_tx_data <= data_reg(7 + byte_cnt_reg * 8 downto byte_cnt_reg * 8);
                        o_uart_tx_valid <= '1';
                    end if;
                    

                    if byte_cnt_reg = TO_INTEGER(unsigned(size_reg)) - 1 then
                        state_next <= IDLE;
                        byte_cnt_next <= 0;
                    else
                        byte_cnt_next <= byte_cnt_reg + 1;
                        state_next <= SEND_BYTES;
                    end if;
                else
                    state_next <= SEND_BYTES;
                end if;
                
             when others =>    
                state_next <= IDLE;
        end case;
        o_axi_awprot <= "000";
        o_axi_arprot <= "000";
    end process;

end rtl;
