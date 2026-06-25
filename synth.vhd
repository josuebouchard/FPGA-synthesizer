library ieee;
use ieee.std_logic_1164.all;

entity synth is
	port(
		-- INPUTS
		Clock, KEY: in std_logic; -- clock and reset 
		SW: in std_logic_vector(8-1 downto 0); --switches 
	
		-- OUTPUTS
		BCLK, LRCLK, DATA : out std_logic
	); 	
end synth;

architecture structural of synth is
begin
	s: entity work.top_synth
		generic map (
			NUM_VOICES => 8,
			-- C4, D4, E4, F4, G4, A4, B4, C5
			-- Distance in semitones from concert A (A4) - distance to frequency - frequency to count - Make it an integer
			-- [-9, -7, -5, -4, -2, 0, 2, 3] .|> n -> 440*2^(n/12) .|> n -> round(50_000_000/n * 0.5) .|> Int
			FREQUENCY_DIVIDER_COUNTS => (47778, 50619, 56818, 63776, 71587, 75843, 85131, 95551),
			MAX_VOICES => 8,
		
			OUT_BITS_NUMBER => 16
		)
		port map (
			Clock, KEY, SW,
			BCLK, LRCLK, DATA
		);

end architecture;