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
generic (width: integer := 4);
port (
	clk : in std_logic;
	reset : in std_logic;
	load : in std_logic;
	par_data : in std_logic_vector(width-1 downto 0);
	serial_data : out std_logic;
	serial_data_valid : out std_logic);
end entity;

architecture rtl of P2S is

signal reg : std_logic_vector (width-1 downto 0);
signal counter_7 : unsigned(2 downto 0);

begin

	data_counter:
	process (clk, reset) begin
		if (reset = '1') then
			counter_7 <= to_unsigned(0,3);
			serial_data_valid <= '0';
			reg <= (others => '0');
		elsif (rising_edge(clk)) then
			if(load = '1') then
				counter_7 <= to_unsigned(6,3);
				serial_data_valid <= '1';
				reg <= par_data;
		   elsif(counter_7 = to_unsigned(0,3)) then
		      counter_7 <= to_unsigned(0,3);
		      serial_data_valid <= '0';
		      reg <= reg;		   
         else
            counter_7 <= counter_7 - 1;
            serial_data_valid <= '1';
            reg(width-2 downto 0) <= reg(width-1 downto 1);
            reg(width-1) <= '0';
			end if;
		end if;
	end process;
	
	serial_data <= reg(0);	
	
end architecture;
