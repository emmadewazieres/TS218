-------------------------------------------------------
-- Design Name : scrambler
-- File Name   : scrambler.vhd
-- Function    : scrambler to randomize data
-- designer    : Camille Leroux - IMS Lab - IPB
-------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity scrambler is
port (
	clk : in std_logic;
	reset : in std_logic;
	init_lfsr : in std_logic;
	enable : in  std_logic;
	enable_output : in std_logic;
	user_clear_data : in std_logic;
	rand_data : out std_logic);
end entity;

architecture rtl of scrambler is

signal reg : std_logic_vector (14 downto 0);
signal linear_feedback : std_logic;

begin

linear_feedback <= (reg(14) xor reg(13));

process (clk, reset) begin
	if (reset = '1') then
		reg <= "000000010101001";
	elsif (rising_edge(clk)) then
		
		if(init_lfsr = '1') then
			reg <= "000000010101001";
		elsif(enable = '1') then
			reg <= (reg(13 downto 0) & linear_feedback);
		end if;

	end if;
end process;

rand_data <= user_clear_data xor (enable_output and linear_feedback);

end architecture;