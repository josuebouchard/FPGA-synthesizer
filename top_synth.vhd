--top level entity 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.synth_pkg.all;

entity top_synth is
	generic (
		NUM_VOICES: natural := 8;
		-- C4, D4, E4, F4, G4, A4, B4, C5
		-- Distance in semitones from concert A (A4) - distance to frequency - frequency to count - Make it an integer
		-- [-9, -7, -5, -4, -2, 0, 2, 3] .|> n -> 440*2^(n/12) .|> n -> round(50_000_000/n * 0.5) .|> Int
		FREQUENCY_DIVIDER_COUNTS: freq_count_array_t := (47778, 50619, 56818, 63776, 71587, 75843, 85131, 95551);
		MAX_VOICES: natural := 8;
		
		OUT_BITS_NUMBER: natural := 16
	);
	port(
		-- INPUTS
		Clock, KEY: in std_logic; -- clock and reset 
		SW: in std_logic_vector(NUM_VOICES - 1 downto 0); --switches 
	
		-- OUTPUTS
		BCLK, LRCLK, DATA : out std_logic
	); 	
end top_synth; 

architecture structural of top_synth is 

-- internal signal 
	signal voices_sig: std_logic_vector (NUM_VOICES - 1 downto 0);
	signal amplitude_sig: std_logic_vector (OUT_BITS_NUMBER - 1 downto 0);
begin 
	
	--voice generator component connections
	voice_gen : entity work.voice_generators
		generic map (
			NUM_VOICES => NUM_VOICES,
			-- C4, D4, E4, F4, G4, A4, B4, C5
			-- Distance in semitones from concert A (A4) - distance to frequency - frequency to count - Make it an integer
			-- [-9, -7, -5, -4, -2, 0, 2, 3] .|> n -> 440*2^(n/12) .|> n -> round(50_000_000/n * 0.5) .|> Int
			FREQUENCY_DIVIDER_COUNTS => (47778, 50619, 56818, 63776, 71587, 75843, 85131, 95551)
		)
		port map( 
			clock_50_mhz => Clock,
			enable => SW,
			output => voices_sig
		);
	--mixer component connections
	mixer: entity work.voice_mixer
		generic map (
			IN_VOICES_NUMBER => NUM_VOICES,
			MAX_VOICES => MAX_VOICES,
			OUT_BITS_NUMBER => OUT_BITS_NUMBER
		)
		port map (
			voices=> voices_sig,
			enable=> SW,
			amplitude=> amplitude_sig
		);
	--i2s component connections
	i2s: entity work.i2s_controller
		generic map (
			AUDIO_IN_BITS => OUT_BITS_NUMBER
		)
		port map ( 
			clk  => Clock,
         reset => KEY,
         audio_in => amplitude_sig,
         bclk=> BCLK,
			lrclk=> LRCLK,
			data_out=> DATA
		);
end architecture; 