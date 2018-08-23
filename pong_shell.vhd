----------------------------------------------------------------------------------
-- Company: Cs56
-- Engineer: David Mena
-- 
-- Create Date: 08/13/2018 02:50:04 PM
-- Design Name: Top Level for pong project
-- Module Name: pong_shell - Behavioral
-- Project Name: Pong Final Project
-- Target Devices: Basys3
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
use ieee.math_real.all;				-- needed for automatic register sizing
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity Pong is
Port (mclk       : in std_logic; --FPGA board master clock (100 MHz)
      --VGA
      VGA_RED : out std_logic_vector(3 downto 0);
      VGA_BLUE : out std_logic_vector(3 downto 0);
      VGA_GREEN : out std_logic_vector(3 downto 0);
      VGA_HS : out std_logic;
      VGA_VS : out std_logic;
      
      --Buttons for gameplay
      pdA_up: in std_logic;
      pdA_down: in std_logic;
      pdB_up: in std_logic;
      pdB_down: in std_logic;
      startPauseButton: in std_logic;
      
      --Buttoons to increase paddle and ball
      ball_big: in std_logic;
      ball_small: in std_logic;
      paddle_big: in std_logic;
      paddle_small: in std_logic;
      
      -- multiplexed seven segment display
      seg	: out std_logic_vector(0 to 6);
      dp    : out std_logic;
      an 	: out std_logic_vector(3 downto 0) );
end Pong;

architecture Behavioral of Pong is

-- COMPONENT DECLARATIONS
component mux7seg is
    Port ( 	clk : in  STD_LOGIC;
           	y0, y1, y2, y3 : in  STD_LOGIC_VECTOR (3 downto 0);	
           	dp_set : in std_logic_vector(3 downto 0);					
           	seg : out  STD_LOGIC_VECTOR (0 to 6);	
           	dp : out std_logic;
           	an : out  STD_LOGIC_VECTOR (3 downto 0) );			
end component;

component VGA IS
PORT ( 	vclk	:	in	STD_LOGIC; --25 MHz clock
		Vsync	: 	out	STD_LOGIC;
		Hsync	: 	out	STD_LOGIC;
        video_on:	out	STD_LOGIC;
		pixel_x	:	out	std_logic_vector( 9 downto 0);
        pixel_y	:	out	std_logic_vector( 9 downto 0));
end component;

component test_pattern is
port( clk           : in std_logic; 
      row, column   : in std_logic_vector( 9 downto 0);
      start_pause   : in std_logic;
      pa_up         : in std_logic;
      pa_down       : in std_logic;
      pb_up         : in std_logic;
      pb_down       : in std_logic;
      color         : out std_logic_vector( 11 downto 0);
      leftwall      : out std_logic;
      rightwall    : out std_logic;
      ballBig              :in std_logic;
      ballSmall            :in std_logic;
      paddleBig            :in std_logic;
      paddleSmall          :in std_logic);
end component;

-- SIGNAL DECLARATIONS
signal color_signal : std_logic_vector(11 downto 0) := (others => '0');
signal x_signal : std_logic_vector(9 downto 0) := (others => '0');
signal y_signal : std_logic_vector(9 downto 0) := (others => '0');
signal v_video_on : std_logic := '1';

----Signals for Monopulsing
signal start_pause_mp: std_logic := '0';
signal start_pause_sync: std_logic_vector(1 downto 0) := "00";


-- SIGNAL DECLARATIONS 
-- Signals for the serial clock divider, which divides the 100 MHz clock down to 1 MHz
constant SCLK_DIVIDER_VALUE: integer := 100 / 50;
--constant CLOCK_DIVIDER_VALUE: integer := 5;     -- for simulation
constant COUNT_LEN: integer := integer(ceil( log2( real(SCLK_DIVIDER_VALUE) ) ));
signal sclkdiv: unsigned(COUNT_LEN-1 downto 0) := (others => '0');  -- clock divider counter
signal sclk_unbuf: std_logic := '0';    -- unbuffered serial clock 
signal sclk: std_logic := '0';          -- internal serial clock

--START PAUSE LOGIC
type state_type is (start, pause);
signal curr_state: state_type := pause; 
signal next_state: state_type;
signal sp :std_logic := '0';

--hitting walls AKA scoring
signal leftwall_signal: std_logic := '0';
signal rightwall_signal: std_logic := '0';

--ScoreBoard Variables
signal left_player : std_logic_vector(3 downto 0) := (others => '0');
signal right_player : std_logic_vector(3 downto 0) := (others => '0');
signal lp: unsigned(3 downto 0) := (others => '0');
signal rp : unsigned(3 downto 0) := (others => '0');
-------------------------------
begin
start_pause_logic: process(curr_state, startPauseButton, leftwall_signal, rightwall_signal, start_pause_mp)
begin
    next_state <= curr_state;
    sp <= '0';
    case curr_state is
        when pause =>
            if start_pause_mp = '1' then
                next_state <= start;
            end if;
        when start =>
            --Variable Here
            sp <= '1';
            if start_pause_mp = '1' then
                next_state <= pause;
            elsif leftwall_signal = '1' then
                next_state <= pause;
            elsif rightwall_signal = '1' then
                next_state <= pause;
            end if;
    end case;
end process start_pause_logic; 

state_update: process(mclk)
begin
	if rising_edge(mclk) then
    	curr_state <= next_state;
    end if;
end process state_update;

left_player <= std_logic_vector(lp);
right_player <= std_logic_vector(rp);
update_scoreboard: process(sclk)
begin
    if rising_edge(sclk) then
        if leftwall_signal = '1' then
            rp <= rp + 1;
            if rp="1001" then
                rp <= "0000";
                lp <= "0000";
            end if;
        elsif rightwall_signal = '1' then
            lp <= lp + 1;
            if lp="1001" then
                lp <= "0000";
                rp <= "0000";
            end if;
        end if ;
    end if;
end process update_scoreboard;

-- Clock buffer for sclk
-- The BUFG component puts the signal onto the FPGA clocking network
Slow_clock_buffer: BUFG
	port map (I => sclk_unbuf,
		      O => sclk );
    
-- Divide the 100 MHz clock down to 2 MHz, then toggling a flip flop gives the final 
-- 1 MHz system clock
Serial_clock_divider: process(mclk)
begin
	if rising_edge(mclk) then
	   	if sclkdiv = SCLK_DIVIDER_VALUE-1 then 
			sclkdiv <= (others => '0');
			sclk_unbuf <= NOT(sclk_unbuf);  --I changed this in order to make it go down to 2HZ instead of 1
		else
			sclkdiv <= sclkdiv + 1;
		end if;
	end if;
end process Serial_clock_divider;


color_distribution: process(mclk, color_signal)
begin
    if v_video_on = '1' then
        VGA_RED <= color_signal(11 downto 8);
        VGA_BLUE <= color_signal (7 downto 4);
        VGA_GREEN <= color_signal (3 downto 0);
    else
        VGA_RED <= "0000";
        VGA_BLUE <= "0000";
        VGA_GREEN <= "0000";
    end if;
end process color_distribution;


--Instantiations
scoreboard: mux7seg port map( 
            clk => mclk,				-- runs on the 1 MHz clock
           	y3 => left_player, 		        
           	y2 => x"f", -- A/D converter output  	
           	y1 => x"f", 		
           	y0 => right_player,		
           	dp_set => "0000",           -- decimal points off HERE IS WHERE YOU DECIDED WHICH DECIMAL POINT
          	seg => seg,
          	dp => dp,
           	an => an );	
           	
display: VGA port map(
        vclk => sclk,
        Vsync => VGA_VS,
        Hsync => VGA_HS,
        video_on => v_video_on,
        pixel_x => x_signal,  --Out STD LOGIC
        pixel_y => y_signal);
    
Game: test_pattern port map(
      clk => sclk,
      row => y_signal,  --In
      column => x_signal, --IN std logic vector
      start_pause => sp,
      pa_up => pdA_up,
      pa_down => pdA_down,
      pb_up => pdB_up,
      pb_down => pdB_down,
      color => color_signal,
      leftwall => leftwall_signal,
      rightwall => rightwall_signal,
      ballBig => ball_big,
      ballSmall => ball_small,
      paddleBig => paddle_big,
      paddleSmall => paddle_small);
      
      
--BUTTON MONOPULSER
monopulser: process(mclk, start_pause_sync, startPauseButton)
begin
    if rising_edge(mclk) then
        start_pause_sync <= startPauseButton & start_pause_sync(1);
    end if;
    
    start_pause_mp <= start_pause_sync(1) and not(start_pause_sync(0));
end process monopulser;

end Behavioral;
