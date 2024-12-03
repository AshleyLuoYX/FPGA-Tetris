library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity grid_generator_simple is
    port (
        clk       : in std_logic;                  -- System clock
        grid      : in std_logic_vector(239 downto 0); -- Input grid (20 rows * 12 columns)
        hcount    : in unsigned(9 downto 0);       -- Horizontal pixel counter
        vcount    : in unsigned(9 downto 0);       -- Vertical pixel counter
        obj_red   : out std_logic_vector(1 downto 0); -- Red color signal
        obj_grn   : out std_logic_vector(1 downto 0); -- Green color signal
        obj_blu   : out std_logic_vector(1 downto 0)  -- Blue color signal
    );
end grid_generator_simple;

architecture Behavioral of grid_generator_simple is
    -- Grid cell dimensions
    constant cell_width : integer := 20;  -- Cell width in pixels
    constant cell_height : integer := 20; -- Cell height in pixels

    -- Start coordinates
    constant start_x : integer := 30;     -- Starting X coordinate
    constant start_y : integer := 30;     -- Starting Y coordinate

    signal grid_x, grid_y : integer;      -- Current grid coordinates
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Calculate grid cell coordinates
            grid_x <= (to_integer(hcount) - start_x) / cell_width; -- Horizontal block index
            grid_y <= (to_integer(vcount) - start_y) / cell_height; -- Vertical block index

            -- Check if pixel is within the grid display area
            if (to_integer(hcount) >= start_x and
                to_integer(hcount) < start_x + (12 * cell_width) and
                to_integer(vcount) >= start_y and
                to_integer(vcount) < start_y + (20 * cell_height)) then

                -- Display block content
                if (grid_x >= 0 and grid_x < 12 and grid_y >= 0 and grid_y < 20 and
                    grid(grid_y * 12 + grid_x) = '1') then
                    obj_red <= "11"; -- Red for locked blocks
                    obj_grn <= "00";
                    obj_blu <= "00";
                else
                    obj_red <= "00"; -- Black for empty cells
                    obj_grn <= "11";
                    obj_blu <= "00";
                end if;

            -- Outside the grid area
            else
                obj_red <= "00"; -- Default background color
                obj_grn <= "00";
                obj_blu <= "00";
            end if;
        end if;
    end process;
end Behavioral;
