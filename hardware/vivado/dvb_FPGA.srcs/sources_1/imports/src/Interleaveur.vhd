----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:46:43 12/12/2011 
-- Design Name: 
-- Module Name:    Brasseur - Behavioral 
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
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Interleaver is
    Port ( H : in  STD_LOGIC;
           Reset : in  STD_LOGIC;
           enable : in std_logic;
           A : in  STD_LOGIC_VECTOR (7 downto 0);
			  B : out  STD_LOGIC_VECTOR(7 downto 0);
			  data_valid : out std_logic);
end Interleaver;

architecture Behavioral of Interleaver is
-- Byte registers
signal temp : STD_LOGIC_VECTOR (7 downto 0); 			--no delay
signal R1 : STD_LOGIC_VECTOR (17*8-1 downto 0); 		--delay: 17 bytes
signal R2 : STD_LOGIC_VECTOR (2*17*8-1 downto 0); 		--delay: 2*17 bytes
signal R3 : STD_LOGIC_VECTOR (3*17*8-1 downto 0); 		--delay: 3*17 bytes
signal R4 : STD_LOGIC_VECTOR (4*17*8-1 downto 0); 		--delay: 4*17 bytes
signal R5 : STD_LOGIC_VECTOR (5*17*8-1 downto 0); 		--delay: 5*17 bytes
signal R6 : STD_LOGIC_VECTOR (6*17*8-1 downto 0); 		--delay: 6*17 bytes
signal R7 : STD_LOGIC_VECTOR (7*17*8-1 downto 0); 		--delay: 7*17 bytes
signal R8 : STD_LOGIC_VECTOR (8*17*8-1 downto 0); 		--delay: 8*17 bytes
signal R9 : STD_LOGIC_VECTOR (9*17*8-1 downto 0); 		--delay: 9*17 bytes
signal R10 : STD_LOGIC_VECTOR (10*17*8-1 downto 0);	--delay: 10*17 bytes
signal R11 : STD_LOGIC_VECTOR (11*17*8-1 downto 0);	--delay: 11*17 bytes
signal cpt_val : std_logic_vector(3 downto 0) := (others => '0');


begin

data_valid <= enable;

P1: process(H, Reset)
	begin 
			-- activities triggered by asynchronous reset (active low)
			if Reset = '1' then
            cpt_val <= "0000";   
			-- activities triggered by rising edge of clock
			elsif H'event and H = '1' then 
				if enable ='1' then
					if cpt_val = "1011" then
						cpt_val <= "0000";
					else
						cpt_val <= cpt_val + 1;
					end if; 
				end if;  
			end if;
end process;

-- shift reg control
P2: process (H, Reset)
		begin
			if Reset = '1' then 
			--Resets registers
			   R1 <= (others=>'0');
				R2 <= (others=>'0');
				R3 <= (others=>'0');
				R4 <= (others=>'0');
				R5 <= (others=>'0');
				R6 <= (others=>'0');
				R7 <= (others=>'0');
				R8 <= (others=>'0');
				R9 <= (others=>'0');
				R10 <= (others=>'0');
				R11 <= (others=>'0');
			
			elsif H = '1' and H'event then 
			   if(enable ='1') then
               --Puts the input byte in the correct registers according to the cpt value (8 firts bits)
               --and puts the 8 last bits of this register in the output byte
               case cpt_val is
                  when "0001" => R1(17*8-1 downto 8) <= R1(17*8-9 downto 0);
                                 R1(7 downto 0) <= A;
                  when "0010" => R2(2*17*8-1 downto 8) <= R2(2*17*8-9 downto 0);
                                 R2(7 downto 0) <= A;
                  when "0011" => R3(3*17*8-1 downto 8) <= R3(3*17*8-9 downto 0);
                                 R3(7 downto 0) <= A;
                  when "0100" => R4(4*17*8-1 downto 8) <= R4(4*17*8-9 downto 0);
                                 R4(7 downto 0) <= A;
                  when "0101" => R5(5*17*8-1 downto 8) <= R5(5*17*8-9 downto 0);
                                 R5(7 downto 0) <= A;
                  when "0110" => R6(6*17*8-1 downto 8) <= R6(6*17*8-9 downto 0);
                                 R6(7 downto 0) <= A;
                  when "0111" => R7(7*17*8-1 downto 8) <= R7(7*17*8-9 downto 0);
                                 R7(7 downto 0) <= A;
                  when "1000" => R8(8*17*8-1 downto 8) <= R8(8*17*8-9 downto 0);
                                 R8(7 downto 0) <= A;
                  when "1001" => R9(9*17*8-1 downto 8) <= R9(9*17*8-9 downto 0);
                                 R9(7 downto 0) <= A;
                  when "1010" => R10(10*17*8-1 downto 8) <= R10(10*17*8-9 downto 0);
                                 R10(7 downto 0) <= A;
                  when "1011" => R11(11*17*8-1 downto 8) <= R11(11*17*8-9 downto 0);
                                 R11(7 downto 0) <= A;
                  when others => NULL;
               end case;
				end if;
			end if;
end process;

--output selection
sel_out: process (cpt_val, A, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11)
		begin
			case cpt_val is
					when "0000" => temp <= A;
					when "0001" => temp <= R1(17*8-1 downto 17*8-8);
					when "0010" => temp <= R2(2*17*8-1 downto 2*17*8-8);
					when "0011" => temp <= R3(3*17*8-1 downto 3*17*8-8);
					when "0100" => temp <= R4(4*17*8-1 downto 4*17*8-8);
					when "0101" => temp <= R5(5*17*8-1 downto 5*17*8-8);
					when "0110" => temp <= R6(6*17*8-1 downto 6*17*8-8);
					when "0111" => temp <= R7(7*17*8-1 downto 7*17*8-8);
					when "1000" => temp <= R8(8*17*8-1 downto 8*17*8-8);
					when "1001" => temp <= R9(9*17*8-1 downto 9*17*8-8);
					when "1010" => temp <= R10(10*17*8-1 downto 10*17*8-8);
					when "1011" => temp <= R11(11*17*8-1 downto 11*17*8-8);
					when others => NULL;
				end case;
end process;

B<=temp;

end Behavioral;

