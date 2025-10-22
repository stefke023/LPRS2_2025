library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_port_bram is
    generic (
        DATA_WIDTH : integer := 16;
        ADDR_WIDTH : integer := 10
    );
    port (
        clk    : in  std_logic;
        
        -- Port A
        we_a   : in  std_logic;
        addr_a : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        din_a  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        dout_a : out std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Port B
        we_b   : in  std_logic;
        addr_b : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        din_b  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        dout_b : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of dual_port_bram is
    constant MEMORY_SIZE : integer := 2**ADDR_WIDTH;
    type ram_type is array (0 to MEMORY_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal ram : ram_type;

    signal dout_a_reg, dout_b_reg : std_logic_vector(DATA_WIDTH-1 downto 0);

    attribute ramstyle : string;
    attribute ramstyle of ram : signal is "M9K";  -- M10K for newer devices
begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- Port A
            if we_a = '1' then
                ram(to_integer(unsigned(addr_a))) <= din_a;
                dout_a_reg <= din_a;  -- write-first
            else
                dout_a_reg <= ram(to_integer(unsigned(addr_a)));
            end if;

            -- Port B
            if we_b = '1' then
                ram(to_integer(unsigned(addr_b))) <= din_b;
                dout_b_reg <= din_b;  -- write-first
            else
                dout_b_reg <= ram(to_integer(unsigned(addr_b)));
            end if;
        end if;
    end process;

    dout_a <= dout_a_reg;
    dout_b <= dout_b_reg;

end architecture rtl;
