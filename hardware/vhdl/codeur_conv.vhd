----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:49:08 11/09/2015 
-- Design Name: 
-- Module Name:    codeur_conv - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity codeur_conv is
	port(
		iClock            : in	std_logic;
		iReset            : in	std_logic;
		iEN	    			: in	std_logic;
		iData            	: in	std_logic;
		oDataX           	: out std_logic;
		oDataY           	: out std_logic
	 );
end codeur_conv;

architecture Behavioral of codeur_conv is

signal registre				: std_logic_vector(1 downto 0) := (others=>'0');


begin
	
	-- implémentation d'un codeur convolutif (5,3) à 3 bascules 

	-- addition modulo 2 pour la sortie X : équation "101"
	oDataX	<= iData xor registre(0);
	
	-- addition modulo 2 pour la sortie Y : équation "011"
	oDataY	<= registre(1) xor registre(0);
	
	

	-- le registre à décalage sur 3 bits
	process(iClock)
	begin
		if(iClock'EVENT and iClock = '1')	then
			if(iReset = '1')	then
				registre		<= (others=>'0');
			else
				if(iEN = '1')	then
					registre		<= iData & registre(registre'HIGH downto 1);
				end if;
			end if;
		end if;
	end process;


end Behavioral;

