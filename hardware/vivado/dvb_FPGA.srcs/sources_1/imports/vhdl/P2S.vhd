-------------------------------------------------------
-- Design Name : deserializer
-- File Name   : deserializer.vhd
-- Function    : bit to byte converter for RS encoder input
-- designer    : Camille Leroux - IMS Lab - IPB
-------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity P2S is
port (
	clk : in std_logic;
	reset : in std_logic;
	load : in std_logic;
	par_data : in std_logic_vector(7 downto 0);
	serial_data : out std_logic;
	serial_data_valid : out std_logic);
end entity;

architecture rtl of P2S is

signal reg : std_logic_vector (7 downto 0);
signal counter_8 : unsigned(2 downto 0);

begin

	data_counter:
	process (clk, reset) begin
		if (reset = '1') then
			counter_8 <= to_unsigned(0,3);
			serial_data_valid <= '0';
			reg <= (others => '0');
		elsif (rising_edge(clk)) then
			if(load = '1') then
				counter_8 <= to_unsigned(7,3);
				serial_data_valid <= '1';
				reg <= par_data;
		   elsif(counter_8 = to_unsigned(0,3)) then
		      counter_8 <= to_unsigned(0,3);
		      serial_data_valid <= '0';
		      reg <= reg;		   
         else
            counter_8 <= counter_8 - 1;
            serial_data_valid <= '1';
            reg(7 downto 1) <= reg(6 downto 0);
            reg(0) <= '0';
			end if;
		end if;
	end process;
	
	serial_data <= reg(7);	
	
end architecture;
