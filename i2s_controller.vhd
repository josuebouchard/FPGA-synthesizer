library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2s_controller is 
	generic (
		AUDIO_IN_BITS: natural := 16
	);
	port (
		clk  : in std_logic; --50MHz
		reset : in std_logic;
		audio_in : in std_logic_vector( AUDIO_IN_BITS-1 downto 0); --mono sample
		bclk, lrclk, data_out: out std_logic

	);
end i2s_controller;

architecture behavior of i2s_controller is 

signal bclk_reg    : std_logic:='0';
signal lrclk_reg     : std_logic :='0';

signal clk_div : integer := 0; 
signal bit_cnt : integer range 0 to 2*AUDIO_IN_BITS - 1 := 0;

signal shift_reg : std_logic_vector (AUDIO_IN_BITS-1 downto 0 );

begin

--Generate the BCLK ( 1.6 MHz from 50 MHz) 
--50MHz /(2x16) = 1.6 MHz
bclk_gen: process(clk)
begin
    if rising_edge(clk) then 
        clk_div <= clk_div +1;
        
        if clk_div = AUDIO_IN_BITS then 
            clk_div <= 0;
            bclk_reg <= not bclk_reg; --BCLK toggles 
        end if;
    end if;
end process;

bclk <=bclk_reg;

-- Shift data on BCLK

shift: process(bclk_reg, reset)
begin 
    if reset ='0' then 
        bit_cnt<= 0 ;
        lrclk_reg<='0';
    elsif rising_edge(bclk_reg) then 
        if bit_cnt = 0 then
             shift_reg <= audio_in;
             lrclk_reg <= '0';  -- Left channel
        elsif bit_cnt = AUDIO_IN_BITS then
             shift_reg <= (others => '0');  -- Right channel (silent for mono)
             lrclk_reg <= '1';
        else
             shift_reg <= shift_reg(AUDIO_IN_BITS-2 downto 0) & '0';
        end if;

        data_out <= shift_reg(AUDIO_IN_BITS-1);
        bit_cnt <= bit_cnt + 1;

        if bit_cnt = 2*AUDIO_IN_BITS-1 then
             bit_cnt <= 0;
        end if;
    end if;
end process; 

lrclk <= lrclk_reg; 

end behavior;