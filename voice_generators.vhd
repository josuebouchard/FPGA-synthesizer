-- Square wave generator

library ieee;
use ieee.std_logic_1164.all;

entity square_wave_generator is
	generic (
		N: integer := 16
	);
	port (
		clock, enable: in std_logic;
		output: out std_logic
	);
end square_wave_generator;

architecture hybrid of square_wave_generator is
	signal count_int: integer := 0;
	signal output_buf: std_logic := '0';
begin
	-- Clocking process
	ps: process (clock)
	begin
		if rising_edge(clock) then
			-- When on: generate square wave
			if enable = '1' then
				-- Overflow
				if count_int = N - 1 then
					count_int <= 0;  	-- Reset counter
					output_buf <= not output_buf; -- Flip wrap
				-- Normal increment
				else
					count_int <= count_int + 1; -- Increment counter
				end if;
			-- When off: clear
			else
				count_int <= 0;  -- Reset counter
				output_buf <= '0';
			end if;
		end if;
	end process;
	
	-- Combinatorial assignments
	output <= output_buf;
end architecture;


-- Voice generator

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.synth_pkg.all;


entity voice_generators is
	generic (
		NUM_VOICES: natural := 8;
		FREQUENCY_DIVIDER_COUNTS: freq_count_array_t := (47778, 50619, 56818, 63776, 71587, 75843, 85131, 95551)
	);
	port (
		clock_50_mhz: in std_logic;
		enable: in std_logic_vector(NUM_VOICES-1 downto 0);
		output: out std_logic_vector(NUM_VOICES-1 downto 0)
	);
end voice_generators;

architecture hybrid of voice_generators is
	signal output_buffer: std_logic_vector(FREQUENCY_DIVIDER_COUNTS'length-1 downto 0);
	
begin

	-- Ensure NUM_VOICES = FREQUENCY_DIVIDER_COUNTS'length
	assert FREQUENCY_DIVIDER_COUNTS'length = NUM_VOICES
		report "NUM_VOICES must match FREQUENCY_DIVIDER_COUNTS length"
		severity failure;

	pulse_gen: for i in 0 to NUM_VOICES-1 generate
		pulse: entity work.square_wave_generator
			generic map (
				-- N = 2 * round(50MHz / f_out)  <- Precalculate
				N => FREQUENCY_DIVIDER_COUNTS(i)  
			)
			port map (
				clock => clock_50_mhz,
				enable => enable(i),
				output => output_buffer(i)
			);
	end generate;

	output <= output_buffer;
	
end architecture;
