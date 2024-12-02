library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Include the tetris_utils package
use work.tetris_utils.all;

entity update_piece_loc is
    port (
        clk       : in  std_logic;                     -- System clock
        reset     : in  std_logic := '0';              -- Reset signal
        grid_in   : in  Grid;                          -- Input grid
        current_x : in  integer;                       -- Current X position of the block
        current_y : in  integer;                       -- Current Y position of the block
        tetromino : in  std_logic_vector(0 to 15);     -- Tetromino data
        new_x     : in  integer;                       -- New X position (left/right)
        new_y     : in  integer;                       -- New Y position (falling down)
        grid_out  : out Grid                           -- Updated grid
    );
end entity;

architecture Behavioral of update_piece_loc is
begin
    process(clk, reset)
        variable temp_grid : Grid; -- Temporary grid to hold intermediate state
    begin
        if rising_edge(clk) then
            -- Start with the input grid
            temp_grid := grid_in;

            -- Clear the previous location of the block
            for row in 0 to 3 loop
                for col in 0 to 3 loop
                    if tetromino((row * 4) + col) = '1' then
                        if (current_y + row >= 0) and (current_y + row < ROWS) and
                           (current_x + col >= 0) and (current_x + col < COLS) then
                            temp_grid(current_y + row, current_x + col) := '0';
                        end if;
                    end if;
                end loop;
            end loop;

            -- Update the new location of the block
            for row in 0 to 3 loop
                for col in 0 to 3 loop
                    if tetromino((row * 4) + col) = '1' then
                        if (new_y + row >= 0) and (new_y + row < ROWS) and
                           (new_x + col >= 0) and (new_x + col < COLS) then
                            temp_grid(new_y + row, new_x + col) := '1';
                        end if;
                    end if;
                end loop;
            end loop;

            -- Output the updated grid
            grid_out <= temp_grid;
        end if;
    end process;
end architecture;