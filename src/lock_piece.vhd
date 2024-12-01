library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;

    -- Include the tetris_utils package
    use work.tetris_utils.all;

entity lock_piece_module is
    port (
        clk       : in  std_logic;                     -- System clock
        reset     : in  std_logic := '0';                     -- Reset signal
        grid_in   : in  Grid;                          -- Input grid
        start_x   : in  integer;                       -- Start X position
        start_y   : in  integer;                       -- Start Y position
        tetromino : in  std_logic_vector(0 to 15); -- Tetromino data
        grid_out  : out Grid                           -- Updated grid
    );
end entity;

architecture Behavioral of lock_piece_module is
begin
    process(clk, reset)
    begin
        if rising_edge(clk) then
            -- Start with the input grid
            grid_out <= grid_in;

            -- Iterate over the 4x4 area of the tetromino
            for row in 0 to 3 loop
                for col in 0 to 3 loop
                    if tetromino((row * 4) + col) = '1' then
                        -- Check boundaries before locking
                        if (start_y + row < ROWS) and (start_x + col < COLS) and 
                           (start_y + row >= 0) and (start_x + col >= 0) then
                            grid_out(start_y + row, start_x + col) <= '1';
                        end if;
                    end if;
                end loop;
            end loop;
        end if;
    end process;
end architecture;
