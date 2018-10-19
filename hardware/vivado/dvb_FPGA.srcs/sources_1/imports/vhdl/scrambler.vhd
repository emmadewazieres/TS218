library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity scrambler is
port(
   iClock            : in	std_logic;
   iReset            : in	std_logic;
   iEN      		 	: in	std_logic;
   iData           	: in	std_logic;
   oDataValid        : out std_logic;
   oData      			: out	std_logic);
end scrambler;

architecture Behavioral of scrambler is

signal reg			: std_logic_vector(3 downto 0);
signal s_data		: std_logic;

begin

process(iClock)
begin
   if(iClock'EVENT and iClock = '1')	then
      if(iReset = '1')	then
         reg <= (others=>'0');
      elsif(iEN = '1')	then
         reg <= s_data & reg(3 downto 1);
      else
         reg <= reg;
      end if;			
   end if;
end process;

	s_data      <= iData xor reg(3) xor reg(2) xor reg(0);
	
	
--	oData	<= s_data;
--	oDataValid <= iEN;

process(iClock, iReset)
begin
   if(iReset = '1')   then
      oData <= '0';
   elsif(iClock'EVENT and iClock = '1')   then
      if(iEN = '1')   then
         oData	<= s_data;
      end if;
   end if;
end process;

process(iClock, iReset)
begin
   if(iReset = '1')   then
      oDataValid <= '0';
   elsif(iClock'EVENT and iClock = '1')   then
      oDataValid <= iEN;      
   end if;
end process;   


end Behavioral;