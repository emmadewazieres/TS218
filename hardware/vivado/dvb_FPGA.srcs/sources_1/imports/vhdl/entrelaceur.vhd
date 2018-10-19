----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    08:32:06 11/09/2015 
-- Design Name: 
-- Module Name:    entrelaceur - Behavioral 
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

use IEEE.numeric_std.all;


entity entrelaceur is
	port(
		iClock            : in	std_logic;
		iReset            : in	std_logic;
		iEN	    			: in	std_logic;	-- compteur de 0 � 6
		iData            	: in	std_logic;
		oData           	: out std_logic
	 );
end entrelaceur;

architecture Behavioral of entrelaceur is

signal reg_1				: std_logic := '0';
signal reg_2				: std_logic_vector(1 downto 0) := (others=>'0');
signal reg_3				: std_logic_vector(2 downto 0) := (others=>'0');
signal reg_4				: std_logic_vector(3 downto 0) := (others=>'0');
signal reg_5				: std_logic_vector(4 downto 0) := (others=>'0');
signal reg_6				: std_logic_vector(5 downto 0) := (others=>'0');

signal en_counter : unsigned(2 downto 0);

begin
	
   enable_counters:
   process (iClock, iReset) begin
      if (rising_edge(iClock)) then
         if (iReset = '1') then
            en_counter <= (others => '0');
         elsif(iEN = '1') then
            if(en_counter = 6) then
               en_counter <= (others => '0');
            else            
               en_counter <= en_counter + 1;
            end if;            
         else
            en_counter <= en_counter;            
         end if;
      end if;
   end process;

	
	-- multiplexeur combinatoire en sortie
	oData		<= iData					when en_counter = "000"	else
					reg_1 				when en_counter = "001"	else
					reg_2(reg_2'HIGH) when en_counter = "010"	else
					reg_3(reg_3'HIGH) when en_counter = "011"	else
					reg_4(reg_4'HIGH) when en_counter = "100"	else
					reg_5(reg_5'HIGH) when en_counter = "101"	else
					reg_6(reg_6'HIGH) when en_counter = "110"	else '0';
	
	
	-- gestion des bascules
	process(iClock)
	begin
		if(iClock'EVENT and iClock = '1')	then
			if(iReset = '1')	then
				reg_1	<= '0';
				reg_2	<= (others=>'0');
				reg_3	<= (others=>'0');
				reg_4	<= (others=>'0');
				reg_5	<= (others=>'0');
				reg_6	<= (others=>'0');
				
			else
			
			-- 1 coup d'horloge sur 7 on active les registres � d�calage
			
				case en_counter is
					when "000"	=> -- la sortie prend directement l'entr�e, pas de bascule ici
					
					when "001"	=> reg_1 <= iData;
					
					when "010"	=> reg_2 <= reg_2(0) & iData;
					
					when "011"	=> reg_3 <= reg_3(1 downto 0) & iData;
					
					when "100"	=> reg_4 <= reg_4(2 downto 0) & iData;
					
					when "101"	=> reg_5 <= reg_5(3 downto 0) & iData;
					
					when "110"	=> reg_6 <= reg_6(4 downto 0) & iData;
					
					when others	=> -- pas cens� arriver.. iEN compris entre "000" et "110"
				end case;
			end if;
		end if;
	end process;


end Behavioral;

