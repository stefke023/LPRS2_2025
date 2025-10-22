library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_transmiter is
    port (
        -- System signals
        i_clk                : in  std_logic;
        i_rstn               : in  std_logic; -- Active low reset
        
        -- UART interface
        o_uart_tx_data       : out std_logic_vector(7 downto 0);
        o_uart_tx_valid      : out std_logic;
        i_uart_tx_busy       : in  std_logic;

        -- CRC and control signals
        i_crc_reg            : in  std_logic_vector(15 downto 0);
        i_crc_calc_data      : in  std_logic_vector(15 downto 0);
        i_crc_calc_done      : in  std_logic;
        
        -- Control inputs
        i_start_tx           : in  std_logic;
        i_mag_reg            : in  std_logic_vector(15 downto 0);
        i_opcode             : in  std_logic;
        i_len_reg            : in  std_logic_vector(6 downto 0);
        i_error_reg          : in  std_logic_vector(7 downto 0);

        -- Buffer control
        o_buff_we            : out std_logic;
        o_buff_raddr         : out std_logic_vector(6 downto 0);
        i_buff_rdata         : in  std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of uart_transmiter is
    -- State types
    type state_t is (MAGIC0, MAGIC1, CRC0, CRC1, ERROR, DATA);
    signal state_reg      : state_t := MAGIC0;
    signal s_tx_data      : std_logic_vector(7 downto 0);
    signal s_tx_valid     : std_logic;
    signal s_buff_raddr   : std_logic_vector(6 downto 0);
    signal s_tx_cnt       : integer range 0 to 126;
    signal s_byte_cnt     : integer range 0 to 3;
    signal s_start_pending: std_logic := '0'; -- Latch for i_start_tx

begin
    uart_tx_proc: process (i_clk, i_rstn)
    begin
        if i_rstn = '0' then
            state_reg       <= MAGIC0;
            s_tx_data       <= (others => '0');
            s_tx_valid      <= '0';
            s_buff_raddr    <= (others => '0');
            s_byte_cnt      <= 0;
            s_tx_cnt        <= 0;
            s_start_pending <= '0';
        elsif rising_edge(i_clk) then
            -- Latch i_start_tx to prevent missing the one-cycle pulse
            if i_start_tx = '1' then
                s_start_pending <= '1';
            end if;

            case state_reg is
                when MAGIC0 =>
                    if s_start_pending = '1' and i_uart_tx_busy = '0' then
                        s_tx_data       <= i_mag_reg(7 downto 0);
                        s_tx_valid      <= '1';
                        s_start_pending <= '0'; -- Clear latch
                    end if;
                    if s_tx_valid = '1' then
                        s_tx_data  <= (others => '0');
                        s_tx_valid <= '0';
                        state_reg  <= MAGIC1;
                    end if;

                when MAGIC1 =>
                    if i_uart_tx_busy = '0' then
                        s_tx_data  <= i_mag_reg(15 downto 8);
                        s_tx_valid <= '1';
                    end if;
                    if s_tx_valid = '1' then
                        s_tx_data  <= (others => '0');
                        s_tx_valid <= '0';
                        state_reg  <= CRC0;
                    end if;

                when CRC0 =>
                    if i_uart_tx_busy = '0' then
                        s_tx_data  <= i_crc_calc_data(7 downto 0);
                        s_tx_valid <= '1';
                    end if;
                    if s_tx_valid = '1' then
                        s_tx_data  <= (others => '0');
                        s_tx_valid <= '0';
                        state_reg  <= CRC1;
                    end if;

                when CRC1 =>
                    if i_uart_tx_busy = '0' then
                        s_tx_data  <= i_crc_calc_data(15 downto 8);
                        s_tx_valid <= '1';
                    end if;
                    if s_tx_valid = '1' then
                        s_tx_data  <= (others => '0');
                        s_tx_valid <= '0';
                        state_reg  <= ERROR;
                    end if;

                when ERROR =>
                    if i_uart_tx_busy = '0' then
                        s_tx_data  <= i_error_reg;
                        s_tx_valid <= '1';
                    end if;
                    if s_tx_valid = '1' then
                        s_tx_data    <= (others => '0');
                        s_tx_valid   <= '0';
                        s_tx_cnt     <= 0;
                        s_byte_cnt   <= 0;
                        --
                        if i_opcode = '0' then
                            if i_error_reg = x"00" then
                                state_reg <= DATA;
                            else
                                state_reg    <= MAGIC0;
                            end if;
                        else
                            state_reg <= MAGIC0;
                        end if;
                    end if;

                when DATA =>
                    if i_uart_tx_busy = '0' then
                        if s_tx_cnt < to_integer(unsigned(i_len_reg)) then
                            s_tx_data  <= i_buff_rdata(7 + s_byte_cnt*8 downto s_byte_cnt*8);
                            s_tx_valid <= '1';
                        else
                            s_tx_cnt     <= 0;
                            s_byte_cnt   <= 0;
                            s_tx_data    <= (others => '0');
                            s_tx_valid   <= '0';
                            state_reg    <= MAGIC0;
                        end if;
                    end if;
                    if s_tx_valid = '1' then
                        s_tx_data  <= (others => '0');
                        s_tx_valid <= '0';
                        if s_byte_cnt = 3 then
                            s_tx_cnt   <= s_tx_cnt + 1;
                            s_byte_cnt <= 0;
                        else
                            s_byte_cnt <= s_byte_cnt + 1;
                        end if;
                    end if;

                when others =>
                    state_reg <= MAGIC0;
            end case;
        end if;
    end process;

    o_buff_raddr    <= std_logic_vector(to_unsigned(s_tx_cnt, 7));
    o_buff_we       <= '0';
    o_uart_tx_data  <= s_tx_data;
    o_uart_tx_valid <= s_tx_valid;
end architecture rtl;