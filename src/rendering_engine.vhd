library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rendering_engine is
    Port (
        clk          : in  std_logic;               -- Clock signal
        reset        : in  std_logic;               -- Reset signal
        grid         : in  std_logic_vector(199 downto 0); -- 10x20 game grid (serialized)
        piece_x      : in  integer range 0 to 9;    -- Active piece X position
        piece_y      : in  integer range 0 to 19;   -- Active piece Y position
        tetromino    : in  std_logic_vector(15 downto 0);  -- 4x4 tetromino matrix
        pixel_x      : in  integer range 0 to 639;  -- Current pixel X coordinate
        pixel_y      : in  integer range 0 to 479;  -- Current pixel Y coordinate
        rgb_out      : out std_logic_vector(2 downto 0) -- RGB output for pixel
    );
end rendering_engine;

architecture Behavioral of rendering_engine is
    -- Constants for grid and cell size
    constant CELL_SIZE : integer := 24; -- Each grid cell size in pixels
    constant GRID_WIDTH : integer := 10; -- Number of columns in the grid
    constant GRID_HEIGHT : integer := 20; -- Number of rows in the grid

    -- Signals for grid coordinates
    signal grid_x, grid_y : integer := 0;
    signal in_grid        : std_logic;
begin
    -- Process for rendering logic
    process (clk)
        variable dx, dy : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rgb_out <= "000"; -- Black on reset
            else
                -- Map pixel coordinates to grid cells
                grid_x <= pixel_x / CELL_SIZE;
                grid_y <= pixel_y / CELL_SIZE;

                -- Check if the pixel is within the grid bounds
                if (grid_x >= 0 and grid_x < GRID_WIDTH and grid_y >= 0 and grid_y < GRID_HEIGHT) then
                    in_grid <= '1';
                else
                    in_grid <= '0';
                end if;

                -- Determine the color of the pixel
                if in_grid = '1' then
                    -- Locked blocks in the grid
                    if grid((grid_y * GRID_WIDTH + grid_x)) = '1' then
                        rgb_out <= "100"; -- Red for locked blocks
                    -- Active tetromino
                    elsif (grid_x >= piece_x and grid_x < piece_x + 4 and
                           grid_y >= piece_y and grid_y < piece_y + 4) then
                        dx := grid_x - piece_x;
                        dy := grid_y - piece_y;

                        if tetromino(dy * 4 + dx) = '1' then
                            rgb_out <= "010"; -- Green for active piece
                        else
                            rgb_out <= "000"; -- Black for empty space
                        end if;
                    else
                        rgb_out <= "000"; -- Black for empty space
                    end if;
                else
                    rgb_out <= "000"; -- Black outside the grid
                end if;
            end if;
        end if;
    end process;
end Behavioral;
