----------------------------------------------------------------------------------
-- Engineer:		David Mena, taken from VGA test patter from Eric Hansen
-- 
-- Create Date:	15:10:36 07/12/2018 
-- Module Name:	Game Mechanics - Behavioral
-- Target Device:	Basys 3 (Artix 7)
--
-- Description:	 Lookup table, receives 10 bit pixel address for 640x480 VGA display
--		and outputs 12-bit SMPTE test pattern
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


ENTITY test_pattern is
	port(	clk                 : in std_logic; 
	        row, column	: in  std_logic_vector( 9 downto 0);
	        start_pause         : in std_logic;
	        pa_up               : in std_logic;
	        pa_down             : in std_logic;
	        pb_up               : in std_logic;
	        pb_down             : in std_logic;
		color		: out std_logic_vector(11 downto 0);
		leftwall            : out std_logic;
		rightwall          : out std_logic;
		ballBig              :in std_logic;
		ballSmall            :in std_logic;
		paddleBig            :in std_logic;
		paddleSmall          :in std_logic);
end test_pattern;

architecture Behavioral of test_pattern is
	
	-- Predefined 12-bit colors that nearly match real test pattern colors
	-- SMPTE 75% color bars
    constant WHITE      : std_logic_vector(11 downto 0) := "110011001100";
    constant YELLOW     : std_logic_vector(11 downto 0) := "110011000000";
    constant CYAN       : std_logic_vector(11 downto 0) := "000011001100";
    constant GREEN      : std_logic_vector(11 downto 0) := "000011000000";
    constant MAGENTA    : std_logic_vector(11 downto 0) := "110000001100";
    constant RED        : std_logic_vector(11 downto 0) := "110000000000";
    constant BLUE       : std_logic_vector(11 downto 0) := "000000001100";

    constant WHITE100   : std_logic_vector(11 downto 0) := "111111111111";  -- 100% white
    constant BLACK      : std_logic_vector(11 downto 0) := "000000000000";
    constant BLACK75    : std_logic_vector(11 downto 0) := "000100010001";  -- 7.5% black
    constant GRAY0      : std_logic_vector(11 downto 0) := "010001000100";
    constant GRAY1      : std_logic_vector(11 downto 0) := "100010001000";
    constant DARK_BLU   : std_logic_vector(11 downto 0) := "000001001000";
    constant DARK_PUR   : std_logic_vector(11 downto 0) := "010000001000";

	signal urow, ucolumn: unsigned(9 downto 0);
	
	---THIS IS PADDLE VARIABLES
	signal paddleAMiddle: integer := 240;
	signal paddleBMiddle: integer := 240;
	signal hsop: integer := 30; --Half Size Of Paddle
	signal paddleThickness: integer := 20;
	
	--BALL VARIABLE
	signal BallMiddleX: integer := 320;
	signal BallMiddleY: integer := 240;
	signal BallSize: integer := 10; --Radius
	
	--Paddle and Ball Counters 
	constant CLK_DIVIDER: integer := 50000; 
	signal paddleCounterA: integer := 0;
	signal pa_up_f, pa_down_f: std_logic := '0'; 
	signal paddleCounterB: integer := 0;
	signal pb_up_f, pb_down_f: std_logic := '0';
	signal ballCounter: integer := 0;
	signal ball_move: std_logic := '0';
    
    --Ball Mechanics
    signal ball_x_velocity: integer := 1; 
    signal ball_y_velocity: integer := 1; 

    --Random Variable for starting
    signal random_start: integer := 0;
    signal ball_x_velocity_f: integer := 1;
    signal ball_y_velocity_f: integer := 1;

    --Random Color Change
    signal change_color: integer := 0;

    --Big and Small Variables
    signal size_counter: integer := 0;
    
begin
--This basically furhter divide the clock
--For the paddles
paddleCountA: process(clk)
begin
    if rising_edge(clk) then
        if(pa_up = '1') then
            paddleCounterA <= paddleCounterA + 1;
            if(paddleCounterA = CLK_DIVIDER) then
                pa_up_f <= '1';
                paddleCounterA <= 0;
            else
                pa_up_f <= '0'; 
            end if;
        elsif(pa_down = '1')then
            paddleCounterA <= paddleCounterA + 1;
            if(paddleCounterA = CLK_DIVIDER) then
                pa_down_f <= '1';
                paddleCounterA <= 0;
            else
                pa_down_f <= '0'; 
            end if;
        end if;
    end if;
end process paddleCountA;

paddleCountB: process(clk)
begin
    if rising_edge(clk) then
        if(pb_up = '1') then
            paddleCounterB <= paddleCounterB + 1;
            if(paddleCounterB = CLK_DIVIDER) then
                pb_up_f <= '1';
                paddleCounterB <= 0;
            else
                pb_up_f <= '0'; 
            end if;
        elsif(pb_down = '1')then
            paddleCounterB <= paddleCounterB + 1;
            if(paddleCounterB = CLK_DIVIDER) then
                pb_down_f <= '1';
                paddleCounterB <= 0;
            else
                pb_down_f <= '0'; 
            end if;
        end if;
    end if;
end process paddleCountB;

--Updates Variable that changes padddle position 
paddle_a: process(clk, pa_up, pa_down)
begin
    if rising_edge(clk) then
        if(pa_up_f = '1') then
            if(paddleAMiddle - hsop > 1) then
                paddleAMiddle <= paddleAMiddle - 1;
            end if;
        elsif(pa_down_f = '1') then
            if(paddleAMiddle + hsop < 480) then
                 paddleAMiddle <= paddleAMiddle + 1;
            end if;
        end if;
    end if;
end process paddle_a;

paddle_b: process(clk, pb_up, pb_down)
begin
    if rising_edge(clk) then
        if(pb_up_f = '1') then
            if(paddleBMiddle - hsop > 1) then
                paddleBMiddle <= paddleBMiddle - 1;
            end if;
        elsif(pb_down_f = '1') then
            if(paddleBMiddle + hsop < 480) then
                 paddleBMiddle <= paddleBMiddle + 1;
            end if;
        end if;
    end if;
end process paddle_b;
--This is case statement is in charge of choosing the
--Starting direction of the ball. 
random_start_direction: process(clk)
begin
    if rising_edge(clk) then
        random_start <= random_start + 1;
        if(random_start = 4) then
            random_start <= 0; 
        end if;
        if (random_start = 0) then
            ball_x_velocity_f <= 1; 
            ball_y_velocity_f <= 1;
        elsif (random_start = 1) then
            ball_x_velocity_f <= -1; 
            ball_y_velocity_f <= -1;
       elsif (random_start = 2) then
            ball_x_velocity_f <= -1; 
            ball_y_velocity_f <= 1; 
        elsif (random_start = 3) then
            ball_x_velocity_f <= 1; 
            ball_y_velocity_f <= -1;
        end if;
    end if; 
end process random_start_direction;

--BallCounter that also further divides the clock
ball_Counter: process(clk)
begin
    if rising_edge(clk) then
        if(start_pause = '1') then
            ballCounter <= ballCounter + 1;
                if(ballCounter = 100000) then
                    ball_move <= '1';
                    ballCounter <= 0;
                else
                    ball_move <= '0'; 
                end if;
        else
            ball_move <= '0';
            --Changing Ball Size
            if(ballBig = '1') then
                size_counter <= size_counter + 1;
                if(size_counter = 100000) then
                    if(BallSize < 50) then
                        BallSize <= BallSize + 1;
                    end if;
                    size_counter <= 0;
                end if;
            elsif(ballSmall = '1') then
                size_counter <= size_counter + 1;
                if(size_counter = 100000) then
                    if(BallSize > 5) then
                        BallSize <= BallSize - 1;
                    end if;
                    size_counter <= 0;
                end if;
            end if;
            --Changing Paddle Size
            if(paddleBig = '1') then
                size_counter <= size_counter + 1;
                if(size_counter = 100000) then
                    if(hsop < 70) then
                        hsop <= hsop + 1;
                    end if;
                    size_counter <= 0;
                end if;
            elsif(paddleSmall = '1') then
                size_counter <= size_counter + 1;
                if(size_counter = 100000) then
                    if(hsop > 10) then
                        hsop <= hsop - 1;
                    end if;
                    size_counter <= 0;
                end if;
            end if;
        end if;
    end if;
end process ball_Counter;

--Ball Mechanics
ball_mechanics: process(clk)
begin
    if rising_edge(clk) then
        leftwall <= '0';
        rightwall <= '0';
        if(ball_move = '1') then
            BallMiddleX <= BallMiddleX + ball_x_velocity;
            BallMiddleY <= BallMiddleY + ball_y_velocity; 
            --Hit a paddle
            if(BallMiddleX - BallSize - paddleThickness = 0) and (BallMiddleY > paddleAMiddle - hsop - 3) and (paddleAMiddle + hsop + 3> BallMiddleY)then --left paddle
                ball_x_velocity <= 1;
                change_color <= change_color + 1; 
                if(change_color = 13) then
                    change_color <= 0;
                end if;
            elsif(BallMiddleX + BallSize + paddleThickness = 640) and (BallMiddleY > paddleBMiddle - hsop) and (paddleBMiddle + hsop > BallMiddleY) then --right paddle
                ball_x_velocity <= -1;
                change_color <= change_color + 1; 
                if(change_color = 13) then
                    change_color <= 0;
                end if;
            --Hit a side wall
            elsif(BallMiddleY - BallSize = 5) then
                ball_y_velocity <= 1;
            elsif(BallMiddleY + BallSize= 485)then
                ball_y_velocity <= -1;
            --Scores
            elsif(BallMiddleX - BallSize < 5) then
                BallMiddleX <= 320;
                BallMiddleY <= 240;
                --Update the velocity with random velocity 
                ball_x_velocity <= ball_x_velocity_f;
                ball_y_velocity <= ball_y_velocity_f;
                leftwall <= '1';
            elsif (BallMiddleX + BallSize > 635) then
                BallMiddleX <= 320;
                BallMiddleY <= 240;
                --Update the velocity with randome velocity
                ball_x_velocity <= ball_x_velocity_f;
                ball_y_velocity <= ball_y_velocity_f;
                rightwall <= '1';
            end if;
        else
            BallMiddleX <= BallMiddleX;
            BallMiddleY <= BallMiddleY;
        end if;
    end if;
end process ball_mechanics;

--This updates all the variables
urow <= unsigned(row); ucolumn <= unsigned(column);
movement: process(urow, ucolumn)
begin
		-- large vertical color bands, evenly spaced horizontally, 320px vertically
		-- Gray, yellow, cyan, green, purple, red, blue
		if (ucolumn >= 5) and (ucolumn < paddleThickness) and (urow >= paddleAMiddle - hsop) and (urow < paddleAMiddle + hsop) then
			color <= WHITE;
		elsif (ucolumn >= 640 - paddleThickness) and (ucolumn < 635) and (urow >= paddleBMiddle - hsop) and (urow < paddleBMiddle + hsop) then
			color <= WHITE;
		elsif (ucolumn >= BallMiddleX - BallSize) and (ucolumn < BallMiddleX + BallSize) and (urow >= BallMiddleY - BallSize) and (urow < BallMiddleY + BallSize) then
			color <= WHITE;
			case change_color is
                when 0 =>
                    color <= WHITE;
                when 2 =>
                    color <= YELLOW;
                when 4 =>
                    color <= CYAN;
                when 6 =>
                    color <= MAGENTA;
                when 8 =>
                    color <= GREEN;
                when 10 =>
                    color <= RED;
                when 12 =>
                    color <= BLUE;
                when others =>
                    color <= WHITE;
            end case;
		-- black for any gaps
		else
			color <= BLACK;
		end if;
end process movement;

end Behavioral;
