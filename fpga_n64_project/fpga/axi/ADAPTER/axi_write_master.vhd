library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi_write_master is
    Port ( 
        -- System signals
        i_clk                : in  std_logic;
        i_rstn               : in  std_logic; -- Active low reset

        -- AXI Lite Master Interface
        -- Write Address Channel
        o_axi_awaddr         : out std_logic_vector(31 downto 0);
        o_axi_awvalid        : out std_logic;
        o_axi_awprot         : out std_logic_vector( 2 downto 0);
        i_axi_awready        : in  std_logic;
        -- Write Data Channel
        o_axi_wdata          : out std_logic_vector(31 downto 0);
        o_axi_wstrb          : out std_logic_vector( 3 downto 0);
        o_axi_wvalid         : out std_logic;
        i_axi_wready         : in  std_logic;
        -- Write Response Channel
        i_axi_bresp          : in  std_logic_vector( 1 downto 0);
        i_axi_bvalid         : in  std_logic;
        o_axi_bready         : out std_logic;

        --Other signals
        i_axi_write_start    : in  std_logic;
        i_address            : in  std_logic_vector(31 downto 0);
        i_data_len           : in  std_logic_vector( 6 downto 0);
        o_buff_raddr         : out std_logic_vector( 6 downto 0);
        o_buff_we            : out std_logic;
        i_buff_rdata         : in  std_logic_vector(31 downto 0);
        o_start_tx           : out std_logic;
        o_error_code         : out std_logic_vector( 7 downto 0)
        
    );
end entity;


architecture rtl of axi_write_master is 
    type state_t is (IDLE, START_AXI, WAIT_HANDSHAKE, BRAM_SINC);
    signal state_reg     : state_t := IDLE;
    signal s_aw_fire     : std_logic;
    signal s_w_fire      : std_logic;
    signal s_b_fire      : std_logic;
    signal s_axi_awvalid : std_logic;
    signal s_axi_wvalid  : std_logic;
    signal s_axi_bready  : std_logic;
    signal s_axi_awaddr  : std_logic_vector(31 downto 0);
    signal s_axi_wdata   : std_logic_vector(31 downto 0);
    signal s_start_tx    : std_logic;
   	signal err_reg       : std_logic_vector( 7 downto 0);
    signal trans_cnt     : integer range 0 to 126;

begin
s_aw_fire <= i_axi_awready and s_axi_awvalid;
s_w_fire  <= i_axi_wready  and s_axi_wvalid;
s_b_fire  <= i_axi_bvalid  and s_axi_bready;

axi_write_proc: process (i_clk, i_rstn) is
begin
	if i_rstn = '0' then
		state_reg     <= IDLE;
        s_axi_awvalid <= '0';
		s_axi_wvalid  <= '0';
        s_axi_bready  <= '0';
        s_axi_awaddr  <= (others => '0');
        s_axi_wdata   <= (others => '0');
        s_start_tx    <= '0';
        err_reg       <= (others => '0');
        trans_cnt     <= 0;

	elsif rising_edge(i_clk) then

		
			case state_reg is 

                when IDLE  =>
                    if i_axi_write_start = '1' then
                        state_reg   <= START_AXI;
                    end if;
                    if s_start_tx  = '1' then
                        s_start_tx  <= '0'; 
                    end if;

                when START_AXI =>
                    s_axi_awvalid <= '1';
                    s_axi_awaddr  <= i_address or std_logic_vector(to_unsigned(trans_cnt * 4, 32)); --Change to addition
		            s_axi_wvalid  <= '1';
                    s_axi_wdata   <= i_buff_rdata;
                    s_axi_bready  <= '1';
                    state_reg     <= WAIT_HANDSHAKE;        

                when WAIT_HANDSHAKE =>
                    if s_aw_fire = '1' then 
                        --s_axi_wdata   <= i_buff_rdata;
                        s_axi_awvalid <= '0';
                        s_axi_awaddr  <= (others => '0');
                    end if;

                    if s_w_fire = '1' then 
                        s_axi_wvalid  <= '0';
                        s_axi_wdata   <= (others => '0');
                    end if; 

                    if s_b_fire = '1' then 
                        if i_axi_bresp /= "00" then --TODO ad error reg and global error reg i adapter file
                            err_reg   <= x"04";
                        end if;
                        s_axi_bready  <= '0';
                        if trans_cnt = to_integer(unsigned(i_data_len) - 1) then
                            s_start_tx  <= '1'; 
                            trans_cnt   <= 0;
                            state_reg   <= IDLE;
                        else
                            trans_cnt   <= trans_cnt + 1;
                            state_reg   <= BRAM_SINC; 
                        end if;
                    end if;

                when BRAM_SINC =>
                    state_reg     <= START_AXI;
                when others =>
                    state_reg     <= IDLE;
            end case;

    end if;
end process;

    o_axi_awaddr   <= s_axi_awaddr;
    o_axi_awvalid  <= s_axi_awvalid;
    o_axi_awprot   <= "000";
    o_axi_wdata    <= s_axi_wdata;
    o_axi_wstrb    <= "1111";
    o_axi_wvalid   <= s_axi_wvalid;
    o_axi_bready   <= s_axi_bready;
    o_start_tx     <= s_start_tx;
    o_buff_we      <= '0';
    o_buff_raddr   <= std_logic_vector(to_unsigned(trans_cnt, 7));
    o_error_code   <= err_reg;

end architecture rtl;