library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi_read_master is
    Port ( 
        -- System signals
        i_clk                : in  std_logic;
        i_rstn               : in  std_logic; -- Active low reset

        -- AXI Lite Master Interface
        -- Read Address Channel
        o_axi_araddr         : out std_logic_vector(31 downto 0);
        o_axi_arvalid        : out std_logic;
        o_axi_arprot         : out std_logic_vector(2 downto 0);
        i_axi_arready        : in  std_logic;
        -- Read Data Channel
        i_axi_rdata          : in  std_logic_vector(31 downto 0);
        i_axi_rresp          : in  std_logic_vector(1 downto 0);
        i_axi_rvalid         : in  std_logic;
        o_axi_rready         : out std_logic;

        --Other signals
        i_axi_read_start     : in  std_logic;
        i_address            : in  std_logic_vector(31 downto 0);
        i_data_len           : in  std_logic_vector( 6 downto 0);
        o_buff_waddr         : out std_logic_vector( 6 downto 0);
        o_buff_we            : out std_logic;
        o_buff_wdata         : out std_logic_vector(31 downto 0);
        o_start_tx           : out std_logic;
        o_error_code         : out std_logic_vector( 7 downto 0)
    );
end axi_read_master;

architecture rtl of axi_read_master is 
    type state_t is (IDLE, START_AXI, WAIT_HANDSHAKE, BRAM_SINC);
    signal state_reg     : state_t := IDLE;
    signal s_ar_fire     : std_logic;
    signal s_r_fire      : std_logic;
    signal s_axi_arvalid : std_logic;
    signal s_axi_rready  : std_logic;
    signal s_axi_araddr  : std_logic_vector(31 downto 0);
    signal s_buff_wdata  : std_logic_vector(31 downto 0);
    signal s_buff_we     : std_logic;
    signal s_start_tx    : std_logic;
    signal err_reg       : std_logic_vector( 7 downto 0);
    signal trans_cnt     : integer range 0 to 126;

begin
s_ar_fire <= i_axi_arready and s_axi_arvalid;
s_r_fire  <= i_axi_rvalid  and s_axi_rready;
axi_read_proc: process (i_clk, i_rstn) is
begin
	if i_rstn = '0' then
		state_reg     <= IDLE;
        s_axi_arvalid <= '0';
		s_axi_rready  <= '0';
        s_axi_araddr  <= (others => '0');
        s_buff_wdata  <= (others => '0');
        s_buff_we     <= '0';
        s_start_tx    <= '0';
        err_reg       <= (others => '0');
        trans_cnt     <= 0;

	elsif rising_edge(i_clk) then

		
			case state_reg is

                when IDLE =>
                    if i_axi_read_start = '1' then
                        state_reg  <= START_AXI;
                    end if;
                    if s_start_tx  = '1' then
                        s_start_tx <= '0'; 
                    end if;

                when START_AXI =>
                    s_axi_arvalid <= '1';
                    s_axi_araddr  <= i_address or std_logic_vector(to_unsigned(trans_cnt * 4, 32)); --Change to addition
                    s_axi_rready  <= '1';
                    state_reg     <= WAIT_HANDSHAKE;        
                
                when WAIT_HANDSHAKE =>
                    if s_ar_fire = '1' then
                        s_axi_arvalid <= '0';
                    end if;
                    if s_r_fire = '1' then
                        if i_axi_rresp /= "00" then --TODO ad error reg and global error reg i adapter file
                            err_reg  <= x"08";
                        end if;
                        s_buff_wdata <= i_axi_rdata;
                        s_buff_we    <= '1';
                        s_axi_rready <= '0';
                        state_reg    <= BRAM_SINC; 
                    end if;

                when BRAM_SINC =>
                    s_buff_we    <= '0';
                    if trans_cnt = to_integer(unsigned(i_data_len) - 1) then
                            s_start_tx  <= '1';
                            trans_cnt   <= 0;
                            state_reg   <= IDLE;
                    else
                            trans_cnt   <= trans_cnt + 1;
                            state_reg   <= START_AXI;
                    end if;                  

                when others =>
                    state_reg    <= IDLE;
            
            end case;
    
    end if;        
    
end process;

    o_axi_arvalid <= s_axi_arvalid;
    o_axi_araddr  <= s_axi_araddr;
    o_axi_arprot  <= "000";
   	o_axi_rready  <= s_axi_rready;

    o_buff_waddr  <= std_logic_vector(to_unsigned(trans_cnt, 7));
    o_buff_wdata  <= s_buff_wdata;
    o_buff_we     <= s_buff_we;

    o_start_tx    <= s_start_tx;
    o_error_code  <= err_reg;

end architecture rtl;