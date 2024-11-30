library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
library UNISIM;
use UNISIM.vcomponents.ALL;

entity vga_controller_tetris is
    Port (
        clk       : in  std_logic;                  -- System clock
        reset     : in  std_logic;                  -- Reset signal
        tx        : out std_logic;                  -- UART TX signal
        red       : out std_logic_vector(1 downto 0); -- VGA red signal
        green     : out std_logic_vector(1 downto 0); -- VGA green signal
        blue      : out std_logic_vector(1 downto 0); -- VGA blue signal
        hsync     : out std_logic;                 -- Horizontal sync
        vsync     : out std_logic                  -- Vertical sync
    );
end vga_controller_tetris;

architecture Behavioral of vga_controller_tetris is
    -- Signals for clock management
    signal clkfb, clkfx : std_logic;

    -- VGA counters and control signals
    signal hcount, vcount : unsigned(9 downto 0) := (others => '0');
    signal blank, frame   : std_logic;

    -- RGB signals for rendering
    signal obj1_red, obj1_grn, obj1_blu : std_logic_vector(1 downto 0);

    -- Static Tetris grid for testing
    signal grid : std_logic_vector(199 downto 0) := (
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0001100000" &
        "0001100000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000" &
        "0000000000"
    );

    -- Grid parameters
    constant CELL_SIZE : integer := 24; -- Size of each grid cell in pixels

begin
    -- UART TX is unused in this design
    tx <= '1';

    ------------------------------------------------------------------
    -- Clock management tile (adjust for your board if necessary)
    ------------------------------------------------------------------
    cmt: MMCME2_BASE generic map (
        BANDWIDTH           => "OPTIMIZED",
        CLKFBOUT_MULT_F     => 50.875,
        CLKIN1_PERIOD       => 83.333,
        CLKOUT0_DIVIDE_F    => 24.250,
        DIVCLK_DIVIDE       => 1
    ) port map (
        CLKOUT0 => clkfx,
        CLKFBOUT => clkfb,
        CLKIN1 => clk,
        CLKFBIN => clkfb,
        PWRDWN => '0',
        RST => '0'
    );

    ------------------------------------------------------------------
    -- VGA display counters
    ------------------------------------------------------------------
    process(clkfx)
    begin
        if rising_edge(clkfx) then
            if reset = '1' then
                hcount <= (others => '0');
                vcount <= (others => '0');
            else
                -- Horizontal counter
                if hcount = to_unsigned(799, 10) then
                    hcount <= (others => '0');
                    -- Vertical counter
                    if vcount = to_unsigned(524, 10) then
                        vcount <= (others => '0');
                    else
                        vcount <= vcount + 1;
                    end if;
                else
                    hcount <= hcount + 1;
                end if;
            end if;

            -- Generate blanking and sync signals
            blank <= '1' when (hcount >= to_unsigned(640, 10) or vcount >= to_unsigned(480, 10)) else '0';
            hsync <= '0' when (hcount >= to_unsigned(656, 10) and hcount <= to_unsigned(751, 10)) else '1';
            vsync <= '0' when (vcount >= to_unsigned(490, 10) and vcount <= to_unsigned(491, 10)) else '1';

            -- Frame signal for the end of active area
            frame <= '1' when (hcount = to_unsigned(639, 10) and vcount = to_unsigned(479, 10)) else '0';
        end if;
    end process;

    ------------------------------------------------------------------
    -- Render Static Tetris Grid and Determine Pixel Color
    ------------------------------------------------------------------
    process(hcount, vcount)
        variable grid_x, grid_y : integer;
    begin
        -- Calculate grid cell indices
        grid_x := to_integer(hcount) / CELL_SIZE;
        grid_y := to_integer(vcount) / CELL_SIZE;

        -- Check if pixel is within the grid
        if (grid_x >= 0 and grid_x < 10 and grid_y >= 0 and grid_y < 20) then
            -- Determine cell content: '1' for filled, '0' for empty
            if grid(grid_y * 10 + grid_x) = '1' then
                obj1_red <= "11"; -- Red for filled cells
                obj1_grn <= "00";
                obj1_blu <= "00";
            else
                obj1_red <= "00"; -- Black for empty cells
                obj1_grn <= "00";
                obj1_blu <= "00";
            end if;
        else
            -- Outside grid area
            obj1_red <= "00";
            obj1_grn <= "00";
            obj1_blu <= "00";
        end if;
    end process;

    ------------------------------------------------------------------
    -- VGA Output with Blanking
    ------------------------------------------------------------------
    red <= b"00" when blank = '1' else obj1_red;
    green <= b"00" when blank = '1' else obj1_grn;
    blue <= b"00" when blank = '1' else obj1_blu;

end Behavioral;
