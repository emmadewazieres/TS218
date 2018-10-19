-------------------------------------------------------
-- Design Name : deserializer
-- File Name   : deserializer.vhd
-- Function    : bit to byte converter for RS encoder input
-- designer    : Camille Leroux - IMS Lab - IPB
-------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;


entity S2P is
port (
	clk : in std_logic;
	reset : in std_logic;
	i_data_valid : in std_logic;
	serial_data : in std_logic;
	par_data : out std_logic_vector(7 downto 0);
	o_data_valid : out std_logic);
end entity;

architecture rtl of S2P is

signal reg : std_logic_vector (7 downto 0);
signal bit_counter_8 : unsigned(2 downto 0);

begin

	data_counter:
	process (clk, reset) begin
		if (reset = '1') then
			bit_counter_8 <= (others => '0');
		elsif (rising_edge(clk)) then
			if(i_data_valid = '1') then
				if(bit_counter_8 = 7) then
					bit_counter_8 <= (others => '0');			
				else
					bit_counter_8 <= bit_counter_8 + 1;
				end if;			
			end if;
		end if;
	end process;
	
process (clk, reset) begin
	if (reset = '1') then
		reg <= (others => '0');
	elsif (rising_edge(clk)) then
		
		if(i_data_valid = '1') then
			reg(6 downto 0) <= (reg(7 downto 1));
			reg(7) <= serial_data;
		end if;

	end if;
end process;

par_data <= reg;

process (clk, reset) begin
	if (reset = '1') then
		o_data_valid <= '0';
	elsif (rising_edge(clk)) then
		if(i_data_valid = '1' and bit_counter_8 = 7) then
			o_data_valid <= '1';
		else
		   o_data_valid <= '0';
		end if;
	end if;
end process;


end architecture;
