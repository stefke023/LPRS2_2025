
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.automotive_types.all;

entity chassis_drive is
	port(
		i_chassis : in  t_chassis;
		o_l_mot_in1 : out std_logic;
		o_l_mot_in2 : out std_logic;
		o_r_mot_in1 : out std_logic;
		o_r_mot_in2 : out std_logic
	);
end entity;

architecture arch of chassis_drive is
	
	signal l_track : t_track;
	signal r_track : t_track;
	
begin
	
	process(i_chassis)
	begin
		case i_chassis is
			when C_IDLE =>
				l_track <= T_COAST;
				r_track <= T_COAST;
			when C_BRAKE =>
				l_track <= T_BRAKE;
				r_track <= T_BRAKE;
			when C_FORWARD =>
				l_track <= T_FORWARD;
				r_track <= T_FORWARD;
			when C_REVERSE =>
				l_track <= T_REVERSE;
				r_track <= T_REVERSE;
			when C_TURN_LEFT =>
				l_track <= T_COAST;
				r_track <= T_FORWARD;
			when C_TURN_RIGHT =>
				l_track <= T_FORWARD;
				r_track <= T_COAST;
			when C_TURN_LEFT_WITH_BRAKE =>
				l_track <= T_BRAKE;
				r_track <= T_FORWARD;
			when C_TURN_RIGHT_WITH_BRAKE =>
				l_track <= T_FORWARD;
				r_track <= T_BRAKE;
			when C_TURN_LEFT_IN_PLACE =>
				l_track <= T_REVERSE;
				r_track <= T_FORWARD;
			when C_TURN_RIGHT_IN_PLACE =>
				l_track <= T_FORWARD;
				r_track <= T_REVERSE;
		end case;
	end process;
	
	
	l_motor_drive_inst: entity work.motor_drive
	port map(
		i_track   => l_track,
		o_mot_in1 => o_l_mot_in1,
		o_mot_in2 => o_l_mot_in2
	);
	r_motor_drive_inst: entity work.motor_drive
	port map(
		i_track   => r_track,
		o_mot_in1 => o_r_mot_in1,
		o_mot_in2 => o_r_mot_in2
	);
	
end architecture;
