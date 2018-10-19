----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/18/2017 04:03:43 PM
-- Design Name: 
-- Module Name: transmitter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
use IEEE.NUMERIC_STD.ALL;

entity transmitter is
    Port ( rst : in STD_LOGIC;
           clk : in STD_LOGIC;
           enable : in STD_LOGIC;
           stream_in : in STD_LOGIC_VECTOR(7 downto 0);
           stream_out : out STD_LOGIC_VECTOR(7 downto 0);
           data_valid : out std_logic);
end transmitter;

architecture Behavioral of transmitter is   

component scrambler is
port (
	clk : in std_logic;
	reset : in std_logic;
	init_lfsr : in std_logic;
	enable : in  std_logic;
	enable_output : in std_logic;
	user_clear_data : in std_logic;
	rand_data : out std_logic);
end component;

component rs_encoder is
  port(
    Data         : out std_logic_vector(7 downto 0);
    Valid        : out std_logic;
    Last         : out std_logic;
    User_Data    : in  std_logic_vector(7 downto 0);
    User_Valid   : in  std_logic;
    User_Last    : in  std_logic;
    User_Busy    : out std_logic;
    Clk          : in  std_logic;
    Rst          : in  std_logic
    );
end component;

component S2P is
port (
	clk : in std_logic;
	reset : in std_logic;
	i_data_valid : in std_logic;
	serial_data : in std_logic;
	par_data : out std_logic_vector(7 downto 0);
	o_data_valid : out std_logic);
end component;

component P2S is
port (
	clk : in std_logic;
	reset : in std_logic;
	load : in std_logic;
	par_data : in std_logic_vector(7 downto 0);
	serial_data : out std_logic;
	serial_data_valid : out std_logic);
end component;

component Interleaver is
    Port ( H : in  STD_LOGIC;
           Reset : in  STD_LOGIC;
           enable : in std_logic;
           A : in  STD_LOGIC_VECTOR (7 downto 0);
			  B : out  STD_LOGIC_VECTOR(7 downto 0);
			  data_valid : out std_logic);
end component;

component conv_encoder is
port (
	clk : in std_logic;
	reset : in std_logic;
	enable : in std_logic;
	data_in : in std_logic;
	x : out std_logic;
	y : out std_logic);
end component;

component FIFO_P2S is
    Port ( rst : in STD_LOGIC;
           clk : in STD_LOGIC;
           enable : in STD_LOGIC;
           shift_in : in STD_LOGIC_VECTOR (7 downto 0);
           shift_out : out STD_LOGIC_VECTOR (7 downto 0);
           data_valid : out STD_LOGIC);
end component;

signal scrambler_out_dv, S2P_out_dv, bch_out_dv, p2s_out_dv : std_logic;
signal scrambler_out : std_logic;
signal S2P_out : std_logic_vector(3 downto 0);
signal bch_out : std_logic_vector(7 downto 0);
signal p2s_out : std_logic;
signal intrl_out : std_logic_vector(7 downto 0);
signal dv_interl : std_logic;
signal x1, x2 : std_logic;

signal bit_counter : unsigned(2 downto 0);
signal byte_counter : unsigned(7 downto 0);
signal rs_byte_counter : unsigned(7 downto 0);
signal last_rs_byte, last_rs_byte_out, rs_busy, rs_dv : std_logic;
signal rs_out : std_logic_vector(7 downto 0);
signal packet_counter : unsigned(2 downto 0);
signal en_counter, dv_counter : unsigned(13 downto 0) := (others => '0');

signal fifo_out, intrl_in : std_logic_vector(7 downto 0);
signal fifo_dv, en_fifo, systematic_dv, parity_dv, intrl_dv_in, rs_busy_dly  : std_logic;

signal x, y : std_logic;

begin

	enable_counters:
	process (clk, rst) begin
		if (rising_edge(clk)) then
         if (rst = '1') then
               en_counter <= (others => '0');
         elsif(enable = '1') then				
				  en_counter <= en_counter + 1;				  
         else
               en_counter <= en_counter;
         end if;
         if (rst = '1') then
               dv_counter <= (others => '0');
         elsif(p2s_out_dv = '1') then            
              dv_counter <= dv_counter + 1;
         else
               dv_counter <= dv_counter;         
         end if;
		end if;
	end process;
	
rs_encode : rs_encoder port map(  Data => rs_out,
                                  Valid => rs_dv,
                                  --Data => stream_out,
                                  --Valid => data_valid,
                                  Last => last_rs_byte_out,
                                  User_Data => stream_in,
                                  User_Valid => enable,
                                  User_Last => last_rs_byte,
                                  User_Busy => rs_busy,
                                  Clk => clk,
                                  Rst => rst );

last_rs_byte <= '1' when (rs_byte_counter = to_unsigned(187,11) and enable = '1') else '0';

process(clk)
begin
   if(clk'event and clk= '1') then
      rs_busy_dly <= rs_busy;
   end if;
end process;
--en_fifo <= rs_busy or last_rs_byte_out;

my_fifo : FIFO_P2S Port map( rst => rst,
           clk => clk,
           enable => rs_busy_dly,
           shift_in => rs_out,
           shift_out => fifo_out,
           data_valid => fifo_dv);

systematic_dv <= rs_dv and not(rs_busy_dly) and not(last_rs_byte_out);
parity_dv <= fifo_dv;
intrl_dv_in <= parity_dv or systematic_dv;  

process(systematic_dv, parity_dv, rs_out, fifo_out)
begin
   if(systematic_dv = '1' and parity_dv = '0') then
      intrl_in <= rs_out;
   elsif(systematic_dv = '0' and parity_dv = '1') then
      intrl_in <= fifo_out;
   end if;
end process;

--stream_out <= intrl_in;

--data_valid <= intrl_dv_in;


pi : Interleaver Port map (  H => clk,
                             Reset => rst,
                             enable => intrl_dv_in,
                             A => intrl_in,
--                             B => stream_out,
--                             data_valid => data_valid);
                             B => intrl_out,
                             data_valid => dv_interl);

ps2_inst : P2S port map(clk => clk,
                        reset => rst,
                        load => dv_interl,
                        par_data => intrl_out,
                        serial_data => p2s_out,
                        serial_data_valid => p2s_out_dv);

CC : conv_encoder port map(clk => clk,
                           reset => rst,
                           enable => p2s_out_dv,
                           data_in => p2s_out,
                           x => x,
                           y => y);

stream_out(0) <= y;
stream_out(1) <= x;
stream_out(7 downto 2) <= (others => '0');

data_valid <= p2s_out_dv;

process (clk, rst) begin
	if (rst = '1') then
		--bit_counter <= (others =>'0');
		rs_byte_counter <= to_unsigned(0,8);
		--packet_counter <= to_unsigned(0,3);
	elsif (rising_edge(clk)) then
	   --if(p2s_out_dv ='1') then
	     --if(bit_counter = to_unsigned(7,3)) then
	     --   bit_counter <= (others =>'0');
	     --else
	     --   bit_counter <= bit_counter + to_unsigned(1,3); 
	     --end if;
	   --end if;
--		if(bit_counter=to_unsigned(1631,11)) then
--			bit_counter <= (others => '0');			
--		else
--			bit_counter <= bit_counter + 1;
--		end if;
		
--		if (bit_counter = to_unsigned(1631,11)) then
--			packet_counter <= packet_counter + 1;
--		end if;
		if(enable = '1') then
         if (rs_byte_counter = to_unsigned(187,11)) then
            rs_byte_counter <= (others => '0');
         else
            rs_byte_counter <= rs_byte_counter + 1;
         end if;
      end if;
	end if;
end process;




--serialize : P2S port map(clk => clk,
--                        reset => rst,
--                        load => dv_interl,
--                        par_data => intrl_out,
--                        serial_data => p2s_out,
--                        serial_data_valid => p2s_out_dv);
                        
--parallelize : S2P port map( clk => clk,
--                            reset => rst,
--                            i_data_valid => p2s_out_dv,
--                            serial_data => p2s_out,
--                            par_data => stream_out,
--                            o_data_valid => data_valid);                        

--scramb : scrambler port map(  clk => clk,
--                              reset => rst,
--                              init_lfsr => rst,
--                              enable => p2s_out_dv,
--                              enable_output => '1',
--                              user_clear_data => p2s_out,
--                              rand_data  => scrambler_out);--stream_out(0)


--s2p_inst : S2P port map( clk => clk,
--                         reset => rst,
--                         i_data_valid => p2s_out_dv,
--                         serial_data => p2s_out,
--                         par_data => stream_out,
--                         o_data_valid => data_valid);



--s2p_inst : S2P generic map(width => 4)
--               port map( clk => clk,
--                         reset => rst,
--                         i_data_valid => scrambler_out_dv,
--                         serial_data => scrambler_out,
--                         par_data => S2P_out,
--                         o_data_valid => S2P_out_dv);

--bch_enc : hamenc port map(rst => rst,
--                          clk => clk,
--                          i_data => S2P_out,
--                          i_dv => S2P_out_dv,
--                          o_data => bch_out,
--                          o_dv => bch_out_dv);

--ps2_inst : P2S generic map(width  => 7)
--               port map(clk => clk,
--                        reset => rst,
--                        load => bch_out_dv,
--                        par_data => bch_out(6 downto 0),
--                        serial_data => p2s_out,
--                        serial_data_valid => p2s_out_dv);

--intrl : entrelaceur port map( iClock => clk,
--                              iReset => rst,
--                              iEN => p2s_out_dv,
--                              iData => p2s_out,
--                              oData => intrl_out);
                              
--cc : codeur_conv port map(		iClock => clk,
--                              iReset => rst,
--                              iEN => p2s_out_dv,
--                              iData => intrl_out,
--                              oDataX => x1,
--                              oDataY => x2);

--stream_out(7 downto 2) <= (others => '0');

--stream_out(0) <= x1;
--stream_out(1) <= x2;

--data_valid <= p2s_out_dv;

--stream_out <= stream_in;
--data_valid <= enable;

end Behavioral;