library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity CRC16_Calculator is
    Port (
        i_clk            : in  std_logic;
        i_rstn           : in  std_logic;
        i_start_wresp    : in  std_logic;
        i_start_rresp    : in  std_logic;
        i_opcode         : in  std_logic;
        i_data_len       : in  std_logic_vector( 6 downto 0);
        i_address        : in  std_logic_vector(31 downto 0);
        i_buff_data      : in  std_logic_vector(31 downto 0);
        i_buff_we        : in  std_logic;
        i_error          : in  std_logic_vector( 7 downto 0);
        o_crc_out        : out std_logic_vector(15 downto 0);
        o_done           : out std_logic
    );
end CRC16_Calculator;

architecture rtl of CRC16_Calculator is
    constant POLYNOME : std_logic_vector(15 downto 0) := x"A001";
    
    type state_reg_t is (IDLE, PROCESS_CMD, PROCESS_ADDR, WAIT_WE, PROCESS_ERR, PROCESS_DATA, FINALIZE);
    signal state_reg : state_reg_t := IDLE;
    
    signal crc_reg         : std_logic_vector(15 downto 0);
    signal byte_counter    : integer range 0 to 3 := 0;
    signal word_counter    : integer range 0 to 127 := 0;
    signal data_len_int    : integer range 0 to 127 := 0;
    
    -- Internal signals for processing
    signal cmd_byte     : std_logic_vector(7 downto 0);
    signal current_data : std_logic_vector(31 downto 0);

    signal s_crc_out    : std_logic_vector(15 downto 0);
    signal s_done       : std_logic;
    
begin
   

    process(i_clk, i_rstn)
        variable crc_temp     : std_logic_vector(15 downto 0);
        variable current_byte : std_logic_vector(7 downto 0);
        variable l : line;
    begin
        if i_rstn = '0' then
            state_reg <= IDLE;
            crc_reg <= (others => '0');
            s_crc_out <= (others => '0');    
            cmd_byte  <= (others => '0');
            current_data <= (others => '0');
            s_done <= '0';
            
        elsif rising_edge(i_clk) then
            cmd_byte <= i_opcode & i_data_len;
            data_len_int <= to_integer(unsigned(i_data_len));

            case state_reg is
                when IDLE =>
                    s_done <= '0';
                    crc_reg <= (others => '0');
                    current_data <= (others => '0');
                    byte_counter <= 0;
                    word_counter <= 0;
                    
                    if i_start_wresp = '1' then
                        state_reg <= PROCESS_CMD;
                    end if;

                    if i_start_rresp = '1' then
                        state_reg <= PROCESS_ERR;
                    end if;    
                    
                when PROCESS_CMD =>
                    -- Process command byte (i_opcode & i_data_len)
                    crc_temp := crc_reg;
                    crc_temp(7 downto 0) := crc_temp(7 downto 0) xor cmd_byte;
                    
                    for i in 0 to 7 loop
                        if crc_temp(0) = '1' then
                            crc_temp := '0' & crc_temp(15 downto 1);
                            crc_temp := crc_temp xor POLYNOME;
                        else
                            crc_temp := '0' & crc_temp(15 downto 1);
                        end if;
                    end loop;
                    -- Debug output
                    write(l, string'("PROCESS_CMD: cmd_byte = "));
                    write(l, cmd_byte);
                    write(l, string'(", crc_reg = "));
                    hwrite(l, crc_reg);
                    writeline(output, l);

                    crc_reg <= crc_temp;
                    state_reg <= PROCESS_ADDR;
                    
                when PROCESS_ADDR =>
                    -- Process address bytes (little-endian)
                    case byte_counter is
                        when 0 => current_byte := i_address(7 downto 0);
                        when 1 => current_byte := i_address(15 downto 8);
                        when 2 => current_byte := i_address(23 downto 16);
                        when 3 => current_byte := i_address(31 downto 24);
                        when others => null;
                    end case;
                    
                    crc_temp := crc_reg;
                    crc_temp(7 downto 0) := crc_temp(7 downto 0) xor current_byte;
                    
                    for i in 0 to 7 loop
                        if crc_temp(0) = '1' then
                            crc_temp := '0' & crc_temp(15 downto 1);
                            crc_temp := crc_temp xor POLYNOME;
                        else
                            crc_temp := '0' & crc_temp(15 downto 1);
                        end if;
                    end loop;
                    
                    -- Debug output
                    write(l, string'("PROCESS_ADDR: byte_counter = "));
                    write(l, byte_counter);
                    write(l, string'(", current_byte = "));
                    hwrite(l, current_byte);
                    write(l, string'(", crc_reg = "));
                    hwrite(l, crc_reg);
                    writeline(output, l);

                    crc_reg <= crc_temp;
                    
                    if byte_counter = 3 then
                        byte_counter <= 0;
                        if i_opcode = '1' and data_len_int > 0 then
                            state_reg <= WAIT_WE;
                        else
                            state_reg <= FINALIZE;
                        end if;
                    else
                        byte_counter <= byte_counter + 1;
                    end if;
                    
                when PROCESS_ERR =>
                    -- Process error byte
                    crc_temp := crc_reg;
                    crc_temp(7 downto 0) := crc_temp(7 downto 0) xor i_error;
                    
                    for i in 0 to 7 loop
                        if crc_temp(0) = '1' then
                            crc_temp := '0' & crc_temp(15 downto 1);
                            crc_temp := crc_temp xor POLYNOME;
                        else
                            crc_temp := '0' & crc_temp(15 downto 1);
                        end if;
                    end loop;
                    -- Debug output
                    write(l, string'("PROCESS_ERR: crc_reg = "));
                    hwrite(l, crc_reg);
                    writeline(output, l);   
                    crc_reg <= crc_temp;

                    if i_opcode = '1' then
                        state_reg <= FINALIZE;
                    else
                        state_reg <= WAIT_WE;
                    end if;

                when WAIT_WE   =>
                    if (i_buff_we = '1') then
                        current_data <= i_buff_data;
                        state_reg    <= PROCESS_DATA;
                    end if;
                    
                when PROCESS_DATA =>
                        -- Process data bytes (little-endian)
                        case byte_counter is
                            when 0 => current_byte := current_data(7 downto 0);
                            when 1 => current_byte := current_data(15 downto 8);
                            when 2 => current_byte := current_data(23 downto 16);
                            when 3 => current_byte := current_data(31 downto 24);
                            when others => null;
                        end case;
                        
                        crc_temp := crc_reg;
                        crc_temp(7 downto 0) := crc_temp(7 downto 0) xor current_byte;
                        
                        for i in 0 to 7 loop
                            if crc_temp(0) = '1' then
                                crc_temp := '0' & crc_temp(15 downto 1);
                                crc_temp := crc_temp xor POLYNOME;
                            else
                                crc_temp := '0' & crc_temp(15 downto 1);
                            end if;
                        end loop;
                        
                        -- Debug output
                        write(l, string'("PROCESS_DATA: word_counter = "));
                        write(l, word_counter);
                        write(l, string'(", byte_counter = "));
                        write(l, byte_counter);
                        write(l, string'(", current_byte = "));
                        hwrite(l, current_byte);
                        write(l, string'(", crc_reg = "));
                        hwrite(l, crc_reg);
                        writeline(output, l);
                        crc_reg <= crc_temp;
                        
                        if byte_counter = 3 then
                            byte_counter <= 0;
                            if word_counter = data_len_int - 1 then
                                state_reg <= FINALIZE;
                            else
                                word_counter <= word_counter + 1;
                                state_reg    <= WAIT_WE;
                            end if;
                        else
                            byte_counter <= byte_counter + 1;
                        end if;
                    
                when FINALIZE =>
                    -- Finalize and output CRC  
                    s_crc_out <= crc_reg;
                    write(l, string'("FINALIZE: Final CRC = "));
                    hwrite(l, crc_reg);
                    writeline(output, l);
                    s_done <= '1';
                    state_reg <= IDLE;
                    
            end case;
        end if;
    end process;
   -- report "Processing byte: " & to_hstring(current_byte);
   -- report "CRC after processing: " & to_hstring(crc_reg);
    o_done    <= s_done;
    o_crc_out <= s_crc_out;

end rtl;