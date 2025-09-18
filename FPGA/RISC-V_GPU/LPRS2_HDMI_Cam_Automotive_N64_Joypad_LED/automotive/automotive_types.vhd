
library ieee;

package automotive_types is
	
	type t_chassis is (
		C_IDLE,
		C_BRAKE,
		C_FORWARD,
		C_REVERSE,
		C_TURN_LEFT,
		C_TURN_RIGHT,
		C_TURN_LEFT_WITH_BRAKE,
		C_TURN_RIGHT_WITH_BRAKE,
		C_TURN_LEFT_IN_PLACE,
		C_TURN_RIGHT_IN_PLACE
	);
	
	type t_track is (
		T_COAST,
		T_REVERSE,
		T_FORWARD,
		T_BRAKE
	);

end package automotive_types;
