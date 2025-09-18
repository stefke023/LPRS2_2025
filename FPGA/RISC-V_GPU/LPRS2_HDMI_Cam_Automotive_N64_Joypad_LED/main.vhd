
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.gpu_types.all;
use work.automotive_types.all;

entity main is
	port (
		i_clk           : in    std_logic; -- 100 MHz
		in_rst          : in    std_logic;
		
		i_cam_rgb       : in    t_rgb888;
		i_pix_phase     : in    t_pix_phase;
		i_pix_x         : in    t_pix_x;
		i_pix_y         : in    t_pix_y;
		o_pix_rgb       : out   t_rgb888;
		
		o_chassis       : out   t_chassis;
		
		io_n64_joypad_1 : inout std_logic;
		io_n64_joypad_2 : inout std_logic;
		
		o_led           : out   std_logic_vector(7 downto 0)
	);
end entity main;

architecture arch of main is
	
begin
	o_led <= x"81";
	
	o_pix_rgb <= 
		x"0000ff" when i_pix_x < 100 else
		x"00ff00" when i_pix_x < 200 else
		x"ff0000" when i_pix_x < 300 else
		i_cam_rgb;
	
	o_chassis <= C_IDLE;

end architecture arch;
