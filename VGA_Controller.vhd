-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY VGA IS
PORT ( 	vclk	:	in	STD_LOGIC; --25 MHz clock
		Vsync	: 	out	STD_LOGIC;
		Hsync	: 	out	STD_LOGIC;
        video_on:	out	STD_LOGIC;
		pixel_x	:	out	std_logic_vector( 9 downto 0);
        pixel_y	:	out	std_logic_vector( 9 downto 0));
end VGA;


architecture behavior of VGA is

signal H_video_on 	: STD_LOGIC := '0';
signal V_video_on 	: STD_LOGIC := '0';
--Add your signals here
signal x            : unsigned(9 downto 0) := (others=>'0');
signal y            : unsigned(9 downto 0) := to_unsigned(479, 10);
signal V_enable     : std_logic;


--VGA Constants (taken directly from VGA Class Notes)
constant left_border 	: integer := 48;  	-- back porch
constant h_display 		: integer := 640;	-- active image
constant right_border 	: integer := 16;	-- front porch
constant h_retrace 		: integer := 96;	-- Hsync pulse width
constant HSCAN 			: integer := left_border + h_display 
							+ right_border + h_retrace; -- =800

constant top_border 	: integer := 29;	-- 29
constant v_display 		: integer := 480;	-- active image
constant bottom_border 	: integer := 10;	-- 10
constant v_retrace 		: integer := 2;		-- Vsync pulse width
constant VSCAN 			: integer := top_border + v_display 
							+ bottom_border + v_retrace; -- =521
                            
BEGIN

-- Hsync generating process
Hsync_proc : process(vclk, x)
begin
	if rising_edge(vclk) then
		if x < HSCAN-1 then
        	x <= x+1;
      	else
        	x<= (others=>'0');
      	end if;
    end if;
    
    if (x>=h_display) and (x<HSCAN) then 
    	H_video_on<='0';
    else 
    	H_video_on <= '1';
	end if;
	
	if (x>= h_display+right_border) and (x<HSCAN-left_border) then
	   Hsync<='0';
	else
	   Hsync <= '1';
	end if;
    
    if(x=HSCAN-left_border) then
    	V_enable <= '1';
    else 
    	V_enable <= '0';
    end if;
end process Hsync_proc;

-- Vsync generating process
Vsync_proc : process(vclk, y)
begin
	if rising_edge(vclk) then
    	if V_enable = '1' then
        	if y<VSCAN-1 then
            	y<=y+1;
          	else
            	y<=(others=>'0');
            end if;
        end if;
    end if;
    
    if(y>= v_display) and (y<VSCAN) then
		v_video_on <='0';
    else
    	v_video_on <='1';
    end if;
    
    if(y>=v_display+bottom_border) and (y<VSCAN-top_border) then
    	Vsync<='0';
    else
    	Vsync<='1';
    end if;

end process Vsync_proc;

-- Only enable video out , when H_video_out and V_video_out are high. 
-- It's important to set the output to zero when you aren't actively displaying video. 
-- That's how the monitor determines the black level.
video_on <= H_video_on and V_video_on;
pixel_x <= std_logic_vector(x);
pixel_y <= std_logic_vector(y);

end behavior;
            