-------------------------------------------------------
-- Design Name : conv_encoder
-- File Name   : conv_encoder.vhd
-- Function    : convolutionnal conv_encoder
-- designer    : Camille Leroux - IMS Lab - IPB
-------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity conv_encoder is
port (clk : in std_logic;
      reset : in std_logic;
      enable : in std_logic;
      data_in : in std_logic;
      x : out std_logic;
      y : out std_logic);
end entity;

architecture rtl of conv_encoder is

signal reg : std_logic_vector (5 downto 0);

begin

process (clk, reset) begin
	if (reset = '1') then
		reg <= (others => '0');
	elsif (rising_edge(clk)) then
	  if(enable = '1') then
	     reg(0) <= data_in;
	     reg(5 downto 1) <= reg(4 downto 0);
     end if;
	end if;
end process;

x <= data_in xor reg(0) xor reg(1) xor reg(2) xor reg(5);
y <= data_in xor reg(1) xor reg(2) xor reg(4) xor reg(5);

end architecture;