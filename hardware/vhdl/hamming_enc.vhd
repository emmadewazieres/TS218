library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
                     
ENTITY hamenc IS
   PORT(rst    : in  std_logic;
        clk    : in  std_logic;
        i_data : in  std_logic_vector(3 downto 0);
        i_dv   : in  std_logic;
        o_data : out std_logic_vector(7 downto 0);
        o_dv   : out std_logic);
END hamenc;

ARCHITECTURE ver2 OF hamenc IS

   signal p0, p1, p2, p3 : std_logic;    --check bits
	
BEGIN

   process (clk, rst)
   begin
	if (rst = '1') then
	  o_data <= (others => '0');
	  o_dv <= '0';
	elsif (rising_edge(clk)) then
		if(i_dv = '1') then
			o_data(4) <= i_data(0) XOR i_data(1) XOR i_data(2);
         o_data(5) <= i_data(1) XOR i_data(2) XOR i_data(3);
         o_data(6) <= i_data(0) XOR i_data(1) XOR i_data(3);
         o_data(7) <= i_data(0) XOR i_data(1) XOR i_data(2) XOR i_data(3);
--         o_data(3) <= i_data(0);
--         o_data(2) <= i_data(1);
--         o_data(1) <= i_data(2);
--         o_data(0) <= i_data(3);
           o_data(3 downto 0) <= i_data(3 downto 0);
         o_dv <= '1';
		else
		   --o_data <= o_data;
		   o_dv <= '0';
		end if;
	end if;
end process;

END ver2;