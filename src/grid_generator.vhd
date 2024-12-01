library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity grid_generator is
    port (
        clk       : in std_logic;                  -- System clock
        grid      : in std_logic_vector(239 downto 0); -- Input grid (20 rows * 12 columns)
        hcount    : in unsigned(9 downto 0);       -- Horizontal pixel counter
        vcount    : in unsigned(9 downto 0);       -- Vertical pixel counter
        obj_red   : out std_logic_vector(1 downto 0); -- Red color signal
        obj_grn   : out std_logic_vector(1 downto 0); -- Green color signal
        obj_blu   : out std_logic_vector(1 downto 0)  -- Blue color signal
    );
end grid_generator;

architecture Behavioral of grid_generator is
    -- Grid cell dimensions
    constant cell_width : integer := 20;  -- Cell width in pixels
    constant cell_height : integer := 20; -- Cell height in pixels

    -- Start coordinates
    constant start_x : integer := 30;     -- Starting X coordinate
    constant start_y : integer := 30;     -- Starting Y coordinate

    constant frame_thickness : integer := 4; -- Thickness of the outer grey frame

    signal grid_x, grid_y : integer;      -- Current grid coordinates
    signal local_x, local_y : integer;    -- Local pixel position within the block
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Calculate grid cell coordinates and local pixel position
            grid_x <= (to_integer(hcount) - start_x) / cell_width; -- Horizontal block index
            grid_y <= (to_integer(vcount) - start_y) / cell_height; -- Vertical block index
            local_x <= (to_integer(hcount) - start_x) mod cell_width; -- X position within block
            local_y <= (to_integer(vcount) - start_y) mod cell_height; -- Y position within block

            -- Check if pixel is within the frame area (outer grey frame)
            if (to_integer(hcount) > start_x - frame_thickness and
                to_integer(hcount) <= start_x + (12 * cell_width) + frame_thickness and
                to_integer(vcount) >= start_y - frame_thickness and
                to_integer(vcount) < start_y + (20 * cell_height) + frame_thickness) then

                -- Render outer light grey frame
                if (to_integer(hcount) <= start_x or
                    to_integer(vcount) < start_y) then
                    obj_red <= "10"; -- Grey for outer frame
                    obj_grn <= "10";
                    obj_blu <= "10";

                -- Render outer light grey frame
                elsif (to_integer(hcount) > start_x + (12 * cell_width) or
                    to_integer(vcount) >= start_y + (20 * cell_height)) then
                    obj_red <= "10"; -- Grey for outer frame
                    obj_grn <= "10";
                    obj_blu <= "10";

                -- Thin light red frame for locked blocks
                elsif (grid_x >= 0 and grid_x < 12 and grid_y >= 0 and grid_y < 20 and
                       grid(grid_y * 12 + grid_x) = '1' and
                       (local_x < 2 or local_y < 2)) then
                    obj_red <= "11"; 
                    obj_grn <= "01";
                    obj_blu <= "01";
                
                -- Thin dark red frame for locked blocks
                elsif (grid_x >= 0 and grid_x < 12 and grid_y >= 0 and grid_y < 20 and
                       grid(grid_y * 12 + grid_x) = '1' and
                       (local_x >= cell_width - 2 or local_y >= cell_height - 2)) then
                    obj_red <= "10"; 
                    obj_grn <= "00";
                    obj_blu <= "00";

                -- Thin dark green frame around empty blocks
                elsif (local_x < 1 or local_x >= cell_width - 1 or
                       local_y < 1 or local_y >= cell_height - 1) then
                    obj_red <= "01"; 
                    obj_grn <= "01";
                    obj_blu <= "01";

                -- Block content
                elsif (grid_x >= 0 and grid_x < 12 and grid_y >= 0 and grid_y < 20 and
                       grid(grid_y * 12 + grid_x) = '1') then
                    obj_red <= "11"; -- Red for locked blocks
                    obj_grn <= "00";
                    obj_blu <= "00";

                -- Empty cell background
                else
                    obj_red <= "00"; 
                    obj_grn <= "00";
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
