library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library UNISIM;
use UNISIM.vcomponents.all;

entity vga_controller_tetris is
    Port (
        clk       : in  std_logic;                  -- System clock
        reset     : in  std_logic;                  -- Reset signal
        tx        : out std_logic;                  -- UART TX signal
        grid      : in  std_logic_vector(239 downto 0); -- Input grid (20 rows * 12 columns)
        red       : out std_logic_vector(1 downto 0); -- VGA red signal
        green     : out std_logic_vector(1 downto 0); -- VGA green signal
        blue      : out std_logic_vector(1 downto 0); -- VGA blue signal
        hsync     : out std_logic;                 -- Horizontal sync
        vsync     : out std_logic                  -- Vertical sync
    );
end vga_controller_tetris;

architecture arch of vga_controller_tetris is
	signal clkfb:    std_logic;
	signal clkfx:    std_logic;
	signal hcount:   unsigned(9 downto 0);
	signal vcount:   unsigned(9 downto 0);
	signal blank:    std_logic;
	signal frame:    std_logic;
	signal obj1_red: std_logic_vector(1 downto 0);
	signal obj1_grn: std_logic_vector(1 downto 0);
	signal obj1_blu: std_logic_vector(1 downto 0);
    
begin
	tx<='1';

	------------------------------------------------------------------
	-- Clock management tile
	--
	-- Input clock: 12 MHz
	-- Output clock: 25.2 MHz
	--
	-- CLKFBOUT_MULT_F: 50.875
	-- CLKOUT0_DIVIDE_F: 24.250
	-- DIVCLK_DIVIDE: 1
	------------------------------------------------------------------
	cmt: MMCME2_BASE generic map (
		-- Jitter programming (OPTIMIZED, HIGH, LOW)
		BANDWIDTH=>"OPTIMIZED",
		-- Multiply value for all CLKOUT (2.000-64.000).
		CLKFBOUT_MULT_F=>50.875,
		-- Phase offset in degrees of CLKFB (-360.000-360.000).
		CLKFBOUT_PHASE=>0.0,
		-- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
		CLKIN1_PERIOD=>83.333,
		-- Divide amount for each CLKOUT (1-128)
		CLKOUT1_DIVIDE=>1,
		CLKOUT2_DIVIDE=>1,
		CLKOUT3_DIVIDE=>1,
		CLKOUT4_DIVIDE=>1,
		CLKOUT5_DIVIDE=>1,
		CLKOUT6_DIVIDE=>1,
		-- Divide amount for CLKOUT0 (1.000-128.000):
		CLKOUT0_DIVIDE_F=>24.250,
		-- Duty cycle for each CLKOUT (0.01-0.99):
		CLKOUT0_DUTY_CYCLE=>0.5,
		CLKOUT1_DUTY_CYCLE=>0.5,
		CLKOUT2_DUTY_CYCLE=>0.5,
		CLKOUT3_DUTY_CYCLE=>0.5,
		CLKOUT4_DUTY_CYCLE=>0.5,
		CLKOUT5_DUTY_CYCLE=>0.5,
		CLKOUT6_DUTY_CYCLE=>0.5,
		-- Phase offset for each CLKOUT (-360.000-360.000):
		CLKOUT0_PHASE=>0.0,
		CLKOUT1_PHASE=>0.0,
		CLKOUT2_PHASE=>0.0,
		CLKOUT3_PHASE=>0.0,
		CLKOUT4_PHASE=>0.0,
		CLKOUT5_PHASE=>0.0,
		CLKOUT6_PHASE=>0.0,
		-- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
		CLKOUT4_CASCADE=>FALSE,
		-- Master division value (1-106)
		DIVCLK_DIVIDE=>1,
		-- Reference input jitter in UI (0.000-0.999).
		REF_JITTER1=>0.0,
		-- Delays DONE until MMCM is locked (FALSE, TRUE)
		STARTUP_WAIT=>FALSE
	) port map (
		-- User Configurable Clock Outputs:
		CLKOUT0=>clkfx,  -- 1-bit output: CLKOUT0
		CLKOUT0B=>open,  -- 1-bit output: Inverted CLKOUT0
		CLKOUT1=>open,   -- 1-bit output: CLKOUT1
		CLKOUT1B=>open,  -- 1-bit output: Inverted CLKOUT1
		CLKOUT2=>open,   -- 1-bit output: CLKOUT2
		CLKOUT2B=>open,  -- 1-bit output: Inverted CLKOUT2
		CLKOUT3=>open,   -- 1-bit output: CLKOUT3
		CLKOUT3B=>open,  -- 1-bit output: Inverted CLKOUT3
		CLKOUT4=>open,   -- 1-bit output: CLKOUT4
		CLKOUT5=>open,   -- 1-bit output: CLKOUT5
		CLKOUT6=>open,   -- 1-bit output: CLKOUT6
		-- Clock Feedback Output Ports:
		CLKFBOUT=>clkfb,-- 1-bit output: Feedback clock
		CLKFBOUTB=>open, -- 1-bit output: Inverted CLKFBOUT
		-- MMCM Status Ports:
		LOCKED=>open,    -- 1-bit output: LOCK
		-- Clock Input:
		CLKIN1=>clk,   -- 1-bit input: Clock
		-- MMCM Control Ports:
		PWRDWN=>'0',     -- 1-bit input: Power-down
		RST=>'0',        -- 1-bit input: Reset
		-- Clock Feedback Input Port:
		CLKFBIN=>clkfb  -- 1-bit input: Feedback clock
	);

	------------------------------------------------------------------
	-- VGA display counters
	--
	-- Pixel clock: 25.175 MHz (actual: 25.2 MHz)
	-- Horizontal count (active low sync):
	--     0 to 639: Active video
	--     640 to 799: Horizontal blank
	--     656 to 751: Horizontal sync (active low)
	-- Vertical count (active low sync):
	--     0 to 479: Active video
	--     480 to 524: Vertical blank
	--     490 to 491: Vertical sync (active low)
	------------------------------------------------------------------
	process(clkfx)
	begin
		if rising_edge(clkfx) then
			-- Pixel position counters
			if (hcount>=to_unsigned(799,10)) then
				hcount<=(others=>'0');
				if (vcount>=to_unsigned(524,10)) then
					vcount<=(others=>'0');
				else
					vcount<=vcount+1;
				end if;
			else
				hcount<=hcount+1;
			end if;
			-- Sync, blank and frame
			if (hcount>=to_unsigned(656,10)) and
				(hcount<=to_unsigned(751,10)) then
				hsync<='0';
			else
				hsync<='1';
			end if;
			if (vcount>=to_unsigned(490,10)) and
				(vcount<=to_unsigned(491,10)) then
				vsync<='0';
			else
				vsync<='1';
			end if;
			if (hcount>=to_unsigned(640,10)) or
				(vcount>=to_unsigned(480,10)) then
				blank<='1';
			else
				blank<='0';
			end if;
			if (hcount=to_unsigned(640,10)) and
				(vcount=to_unsigned(479,10)) then
				frame<='1';
			else
				frame<='0';
			end if;
		end if;
	end process;

    ------------------------------------------------------------------
    -- Render Static Tetris Grid and Determine Pixel Color
    ------------------------------------------------------------------
    process(hcount, vcount, clkfx)
        variable dx, dy : integer; -- Grid cell size in pixels
        variable grid_x, grid_y : integer; -- Current grid position
    begin
        if rising_edge(clkfx) then
			-- Calculate grid cell coordinates based on pixel location
			dx := to_integer(hcount) / 24; -- Divide pixel X by cell size (24 pixels per grid cell)
			dy := to_integer(vcount) / 24; -- Divide pixel Y by cell size

			-- Determine grid cell coordinates
			grid_x := 11 - dx; -- Horizontal grid index
			grid_y := 19 - dy; -- Vertical grid index

			-- Check if within grid boundaries
			if (grid_x >= 0 and grid_x < 12 and grid_y >= 0 and grid_y < 20) then
				-- Check grid content: '1' for locked block, '0' for empty
				if grid(grid_y * 12 + grid_x) = '1' then
					obj1_red <= "11"; -- Red for locked blocks
					obj1_grn <= "00";
					obj1_blu <= "00";
				else
					obj1_red <= "00"; -- Black for empty grid cells
					obj1_grn <= "11";
					obj1_blu <= "00";
				end if;
			else
				-- Outside grid boundaries
				obj1_red <= "00";
				obj1_grn <= "00";
				obj1_blu <= "00";
			end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- VGA Output with Blanking
    ------------------------------------------------------------------
    red <= b"00" when blank = '1' else obj1_red;
    green <= b"00" when blank = '1' else obj1_grn;
    blue <= b"00" when blank = '1' else obj1_blu;


end arch;
