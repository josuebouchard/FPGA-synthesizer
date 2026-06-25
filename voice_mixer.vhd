library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity voice_mixer is
	generic (
		IN_VOICES_NUMBER: natural := 8;
		MAX_VOICES: natural := 8;
		OUT_BITS_NUMBER: natural := 16
	);
   port(
		voices: in std_logic_vector(IN_VOICES_NUMBER-1 downto 0);
      enable: in std_logic_vector(IN_VOICES_NUMBER-1 downto 0);
      amplitude: out std_logic_vector(OUT_BITS_NUMBER-1 downto 0)
	);
end voice_mixer;

architecture behavioral of voice_mixer is
begin

    ps: process(enable, voices)
        variable count_integer: integer;
    begin
        -- Initialize variables
		  count_integer := 0;
    
        -- Grab each voice signal (0 to 1 square wave),
        -- interpolate it into a -1 to 1 square wave,
        -- and add it to the counter
        -- Disabled waves have value 0
        for i in 0 to IN_VOICES_NUMBER - 1 loop
            if enable(i) = '1' then
                if voices(i) = '1' then
                    count_integer := count_integer + 1;
                else
                    count_integer := count_integer - 1;
                end if;
            end if;
        end loop;
        
        -- Performs scaling and conversion to signed integer
        amplitude <= std_logic_vector(
			to_signed(
				count_integer * (2**(OUT_BITS_NUMBER - 1) - 1)/MAX_VOICES,
				OUT_BITS_NUMBER
			)
		  );
    end process;    
end architecture;