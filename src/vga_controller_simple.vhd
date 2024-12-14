library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library UNISIM;
use UNISIM.vcomponents.all;

use work.tetris_utils.all;

entity vga_controller_simple_tetris is
    Port (
        clk       : in  std_logic;                  -- System clock
        reset     : in  std_logic;                  -- Reset signal
        tx        : out std_logic;                  -- UART TX signal
        grid      : in  std_logic_vector(ROWS * COLS - 1 downto 0); -- Input grid (20 rows * 12 columns)
        red       : out std_logic_vector(1 downto 0); -- VGA red signal
        green     : out std_logic_vector(1 downto 0); -- VGA green signal
        blue      : out std_logic_vector(1 downto 0); -- VGA blue signal
        hsync     : out std_logic;                 -- Horizontal sync
        vsync     : out std_logic;                  -- Vertical sync
        game_over : in std_logic
    );
end vga_controller_simple_tetris;

architecture arch of vga_controller_simple_tetris is
	signal clkfb:    std_logic;
	signal clkfx:    std_logic;
	signal hcount:   unsigned(9 downto 0);
	signal vcount:   unsigned(9 downto 0);
	signal blank:    std_logic;
	signal frame:    std_logic;
	signal obj1_red: std_logic_vector(1 downto 0);
	signal obj1_grn: std_logic_vector(1 downto 0);
	signal obj1_blu: std_logic_vector(1 downto 0);

	-- Signals from grid_generator
    signal grid_red: std_logic_vector(1 downto 0);
    signal grid_grn: std_logic_vector(1 downto 0);
    signal grid_blu: std_logic_vector(1 downto 0);
    
	-- Signals from title_generator
	signal title_red: std_logic_vector(1 downto 0);
	signal title_grn: std_logic_vector(1 downto 0);
	signal title_blu: std_logic_vector(1 downto 0);

	-- Signals for Score Title Generator
	signal score_title_red: std_logic_vector(1 downto 0);
	signal score_title_grn: std_logic_vector(1 downto 0);
	signal score_title_blu: std_logic_vector(1 downto 0);

	-- Signals for Next Block Generator
	signal next_block_red : std_logic_vector(1 downto 0);
	signal next_block_grn : std_logic_vector(1 downto 0);
	signal next_block_blu : std_logic_vector(1 downto 0);
	signal next_block : std_logic_vector(0 to 15) := "1000100011000000"; -- Data for the next 4x4 block
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
    -- Instantiate Grid Generator
    ------------------------------------------------------------------
    grid_gen_inst: entity work.grid_generator
        port map (
            clk => clkfx,
            grid => grid,
            hcount => hcount,
            vcount => vcount,
            obj_red => grid_red,
            obj_grn => grid_grn,
            obj_blu => grid_blu
        );

	------------------------------------------------------------------
	-- Instantiate Title Generator
	------------------------------------------------------------------
	title_gen_inst: entity work.title_generator
		port map (
			clk => clkfx,
			hcount => hcount,
			vcount => vcount,
			obj_red => title_red,
			obj_green => title_grn,
			obj_blue => title_blu
		);
	
	------------------------------------------------------------------
	-- Instantiate Score Title Generator
	------------------------------------------------------------------
	score_title_gen_inst: entity work.score_title_generator
		port map (
			clk => clkfx,
			hcount => hcount,
			vcount => vcount,
			obj_red => score_title_red,
			obj_green => score_title_grn,
			obj_blue => score_title_blu
		);

    ------------------------------------------------------------------
    -- VGA Output with Blanking and Placement
    ------------------------------------------------------------------
	process(hcount, vcount, blank, clkfx)
	begin
		if (hcount < to_unsigned(300, 10)) then -- Place grid on left side
			obj1_red <= grid_red;
			obj1_grn <= grid_grn;
			obj1_blu <= grid_blu;
        elsif (hcount >= to_unsigned(300, 10) and hcount < to_unsigned(639, 10) and
			vcount >= to_unsigned(30, 10) and vcount < to_unsigned(95, 10)) then
            obj1_red <= title_red;
            obj1_grn <= title_grn;
            obj1_blu <= title_blu;
		elsif (hcount >= to_unsigned(350, 10) and hcount < to_unsigned(539, 10) and
			vcount >= to_unsigned(130, 10) and vcount < to_unsigned(420, 10)) then
			if game_over = '1' then
				obj1_red <= score_title_red;
				obj1_grn <= score_title_grn;
				obj1_blu <= score_title_blu;
			else
				obj1_red <= "00";
				obj1_grn <= "00";
				obj1_blu <= "00";
			end if;
			
		else
			obj1_red <= "00";
			obj1_grn <= "00";
			obj1_blu <= "00";
		end if;
	end process;

	red <= b"00" when blank = '1' else obj1_red;
	green <= b"00" when blank = '1' else obj1_grn;
	blue <= b"00" when blank = '1' else obj1_blu;

end arch;
