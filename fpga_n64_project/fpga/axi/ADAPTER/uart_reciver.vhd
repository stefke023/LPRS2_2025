library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_reciver is
	generic(
        MAGIC_WORD : std_logic_vector(15 downto 0) := x"ABCD"  -- Magic word to identify start of a packet
    );
	port(
		-- On MAX1000.
		-- System signals.
		i_clk                :  in std_logic;
		i_rstn               :  in std_logic; -- Active low reset.
		
		i_byte_rx_data       :  in std_logic_vector(7 downto 0);
		i_byte_rx_valid      :  in std_logic;

		i_crc_calc_data      :  in  std_logic_vector(15 downto 0);
        o_crc_calc_start     :  out std_logic;
		i_crc_calc_done      :  in  std_logic;

        o_start_axi_write    :  out std_logic;
        o_start_axi_read     :  out std_logic;
		o_start_tx		     :  out std_logic;
        
		o_buff_we            :  out std_logic;
		o_buff_waddr         :  out std_logic_vector( 6 downto 0);
        o_buff_wdata         :  out std_logic_vector(31 downto 0);

		o_mag_reg            :  out std_logic_vector(15 downto 0);
		o_crc_reg            :  out std_logic_vector(15 downto 0);
		o_opcode             :  out std_logic;
		o_data_len           :  out std_logic_vector( 6 downto 0);
		o_address            :  out std_logic_vector(31 downto 0);
		o_error_code         :  out std_logic_vector( 7 downto 0)

		
	);
end entity;

architecture rtl of uart_reciver is
 -- State types
    type state_t is (MAGIC0, MAGIC1, CRC0, CRC1, OP_LEN, ADDR0, ADDR1, ADDR2, ADDR3, DATA0, DATA1, DATA2, DATA3, CRC_CTRL);
    signal state_reg    : state_t := MAGIC0;
	signal mag_reg      : std_logic_vector(15 downto 0);
	signal crc_data_reg : std_logic_vector(15 downto 0);
	signal op_reg       : std_logic;
	signal len_reg      : std_logic_vector(6 downto 0);
	signal rem_len_reg  : unsigned(6 downto 0);
	signal addr_reg     : std_logic_vector(31 downto 0);
	signal data_reg     : std_logic_vector(31 downto 0);
	signal tmp_data_reg : std_logic_vector(31 downto 0);
	signal err_reg      : std_logic_vector( 7 downto 0);
	signal s_buff_we    : std_logic;
	signal s_buff_addr  : std_logic_vector( 6 downto 0);
	signal s_crc_calc_start  : std_logic;
	signal s_start_axi_write : std_logic; 
	signal s_start_axi_read  : std_logic;
	signal s_start_tx        : std_logic;
begin

uart_rx_proc: process (i_clk, i_rstn)
begin
	if i_rstn = '0' then
		state_reg    <= MAGIC0;
		mag_reg      <= (others => '0');
		crc_data_reg <= (others => '0');
		op_reg       <= '0';
		len_reg      <= (others => '0');
		rem_len_reg  <= (others => '0');  
		addr_reg     <= (others => '0');
		data_reg     <= (others => '0');
		tmp_data_reg <= (others => '0');
		err_reg      <= (others => '0');
		s_buff_we    <= '0';
		s_buff_addr  <= (others => '0');
		s_start_axi_write <= '0';
		s_start_axi_read  <= '0';
		s_start_tx        <= '0';
		s_crc_calc_start  <= '0';

	elsif rising_edge(i_clk) then

			if s_buff_we = '1' then
				s_buff_we    <= '0';
			end if;
			
			case state_reg is 

			when MAGIC0 =>
				if (i_byte_rx_valid = '1') then
					if i_byte_rx_data = MAGIC_WORD(7 downto 0) then
						mag_reg      <= i_byte_rx_data & mag_reg(15 downto 8);
						state_reg    <= MAGIC1;
					else
						state_reg <= MAGIC0;	
					end if;					
				end if;

			when MAGIC1 =>
				if (i_byte_rx_valid = '1') then
					if i_byte_rx_data = MAGIC_WORD(15 downto 8) then
						mag_reg   <= i_byte_rx_data & mag_reg(15 downto 8);
						state_reg <= CRC0;
					else
						state_reg <= MAGIC0;	
					end if;
				end if;

			when CRC0  =>
				if (i_byte_rx_valid = '1') then
					crc_data_reg    <= i_byte_rx_data & crc_data_reg(15 downto 8);
					state_reg  <= CRC1;  
				end if;

			when CRC1  =>
				if (i_byte_rx_valid = '1') then
					crc_data_reg    <= i_byte_rx_data & crc_data_reg(15 downto 8);
					state_reg  <= OP_LEN;
				end if;

			when OP_LEN  =>
				if (i_byte_rx_valid = '1') then
					op_reg      <= i_byte_rx_data(7);
					len_reg     <= i_byte_rx_data(6 downto 0);
					rem_len_reg <= unsigned(i_byte_rx_data(6 downto 0)) - 1;
					state_reg   <= ADDR0;				
				end if;

			when ADDR0  =>
				if (i_byte_rx_valid = '1') then
					addr_reg   <= i_byte_rx_data & addr_reg(31 downto 8);
					state_reg  <= ADDR1;
				end if;

			when ADDR1  =>
				if (i_byte_rx_valid = '1') then
					addr_reg   <= i_byte_rx_data & addr_reg(31 downto 8);
					state_reg  <= ADDR2;
				end if;

			when ADDR2  =>
				if (i_byte_rx_valid ='1') then
					addr_reg   <= i_byte_rx_data & addr_reg(31 downto 8);
					state_reg  <= ADDR3;
				end if;

			when ADDR3  =>
				if (i_byte_rx_valid = '1') then
					addr_reg   <= i_byte_rx_data & addr_reg(31 downto 8);
					if op_reg = '1' then
						state_reg  <= DATA0;
					else
						state_reg  <= CRC_CTRL;
					end if;
					s_crc_calc_start <= '1';
				end if;

			when DATA0  =>
				s_crc_calc_start <= '0';
				if (i_byte_rx_valid = '1') then
					data_reg   <= i_byte_rx_data & data_reg(31 downto 8);
					state_reg  <= DATA1;
				end if;

			when DATA1  =>
				if (i_byte_rx_valid = '1') then
					data_reg   <= i_byte_rx_data & data_reg(31 downto 8);
					state_reg  <= DATA2;
				end if;

			when DATA2  =>
				if (i_byte_rx_valid = '1') then
					data_reg   <= i_byte_rx_data & data_reg(31 downto 8);
					state_reg  <= DATA3;
				end if;

			when DATA3  =>
				if (i_byte_rx_valid = '1') then
					data_reg     <= i_byte_rx_data & data_reg(31 downto 8);
					s_buff_addr  <= std_logic_vector(unsigned(len_reg) - rem_len_reg - 1);
					tmp_data_reg <= i_byte_rx_data & data_reg(31 downto 8);	
					s_buff_we    <= '1';
					if rem_len_reg = 0 then
						state_reg   <= CRC_CTRL;    	
					else
						rem_len_reg <= rem_len_reg - 1;
						state_reg   <= DATA0;
					end if;	
				end if;
					
			when CRC_CTRL =>
				s_crc_calc_start <= '0';
				if op_reg = '1' then 
					if i_crc_calc_done = '1' then
						if i_crc_calc_data /= crc_data_reg then
							err_reg         <= x"01";
							s_start_tx		<= '1';
						else
							s_start_axi_write <= '1';
						end if;	
					end if;
					if s_start_axi_write = '1' or s_start_tx = '1' then
						s_start_axi_write <= '0';
						s_start_tx        <= '0';
						state_reg        <= MAGIC0;							
					end if;
				else
					if i_crc_calc_done = '1' then
						if i_crc_calc_data /= crc_data_reg then
							err_reg         <= x"02";
							s_start_tx		<= '1';
						else
							s_start_axi_read <= '1';
						end if;
					end if;
					if s_start_axi_read = '1' or s_start_tx = '1' then
						s_start_axi_read <= '0';
						s_start_tx       <= '0';
						state_reg        <= MAGIC0;							
					end if;	
				end if;

			when others =>
				state_reg <= MAGIC0;
			end case;

	end if;
end process;

o_mag_reg         <= mag_reg;
o_crc_reg         <= crc_data_reg;
o_opcode          <= op_reg;
o_data_len        <= len_reg;
o_address         <= addr_reg;
o_buff_wdata      <= tmp_data_reg;
o_buff_we         <= s_buff_we;
o_buff_waddr      <= s_buff_addr;
o_error_code      <= err_reg;
o_start_axi_write <= s_start_axi_write;
o_start_axi_read  <= s_start_axi_read;
o_start_tx        <= s_start_tx;
o_crc_calc_start  <= s_crc_calc_start;
end architecture rtl; 	
