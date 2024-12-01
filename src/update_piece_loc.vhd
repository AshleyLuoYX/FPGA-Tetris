library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Include the tetris_utils package
use work.tetris_utils.all;

entity update_piece_loc is
    port (
        clk        : in  std_logic;                     -- System clock
        reset      : in  std_logic := '0';              -- Reset signal
        grid_in    : in  Grid;                          -- Input grid
        current_x  : in  integer;                       -- Current X position of the block
        current_y  : in  integer;                       -- Current Y position of the block
        tetromino  : in  std_logic_vector(15 downto 0); -- Tetromino data (4x4 matrix)
        move_left  : in  std_logic;                     -- Move left signal
        move_right : in  std_logic;                     -- Move right signal
        rotate     : in  std_logic;                     -- Rotate signal
        move_down  : in  std_logic;                     -- Move down signal (falling)
        block_type : in  integer range 0 to 6;          -- Tetromino type
        rotation   : inout integer range 0 to 3;        -- Rotation index
        grid_out   : out Grid;                          -- Updated grid
        new_x      : out integer;                       -- Updated X position
        new_y      : out integer                        -- Updated Y position
    );
end entity;

architecture Behavioral of update_piece_loc is
    signal temp_grid : Grid;                             -- Temporary grid for intermediate updates
    signal new_tetromino : std_logic_vector(15 downto 0); -- New tetromino after rotation
begin
    process(clk, reset)
        variable new_rotation : integer range 0 to 3;    -- Declare variable at the start of the process
    begin
        if reset = '1' then
            -- Reset the grid and positions
            grid_out <= (others => (others => '0'));
            new_x <= 0;
            new_y <= 0;
        elsif rising_edge(clk) then
            -- Start with the input grid
            temp_grid := grid_in;

            -- Clear the current location of the block
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

            -- Update position and handle movements
            new_x <= current_x;
            new_y <= current_y;
            new_tetromino <= tetromino; -- Default: no rotation

            -- Handle left movement
            if move_left = '1' then
                if not collision_detected(current_x - 1, current_y, tetromino, temp_grid) then
                    new_x <= current_x - 1;
                end if;
            end if;

            -- Handle right movement
            if move_right = '1' then
                if not collision_detected(current_x + 1, current_y, tetromino, temp_grid) then
                    new_x <= current_x + 1;
                end if;
            end if;

            -- Handle rotation
            if rotate = '1' then
                new_rotation := (rotation + 1) mod 4; -- Calculate the new rotation
                new_tetromino := rotate_piece(block_type, new_rotation); -- Get rotated tetromino
                if not collision_detected(current_x, current_y, new_tetromino, temp_grid) then
                    rotation <= new_rotation; -- Update rotation if no collision
                end if;
            end if;

            -- Handle falling (down movement)
            if move_down = '1' then
                if not collision_detected(current_x, current_y + 1, tetromino, temp_grid) then
                    new_y <= current_y + 1;
                end if;
            end if;

            -- Update the new location of the block
            for row in 0 to 3 loop
                for col in 0 to 3 loop
                    if new_tetromino((row * 4) + col) = '1' then
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

