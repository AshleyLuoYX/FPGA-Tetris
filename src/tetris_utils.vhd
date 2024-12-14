library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package tetris_utils is

    -- Constants
    constant ROWS : integer := 23;                -- Number of rows in the grid
    constant COLS : integer := 16;                -- Number of columns in the grid

    function fetch_tetromino(
        block_type : integer range 0 to 6; rotation : integer range 0 to 3
    ) return std_logic_vector;

end tetris_utils;

package body tetris_utils is

     -- Fetch Tetromino Function
    function fetch_tetromino(
        block_type : integer range 0 to 6; rotation : integer range 0 to 3
    ) return std_logic_vector is
        -- ROM Data for Tetromino Shapes
        type rom_type is array (0 to 6, 0 to 3) of std_logic_vector(15 downto 0);
        constant Tetromino_ROM : rom_type := (
            -- I Tetromino
            ("1000100010001000", "0000111100000000", "1000100010001000", "0000111100000000"),
            -- O Tetromino
            ("1100110000000000", "1100110000000000", "1100110000000000", "1100110000000000"),
            -- T Tetromino
            ("1110010000000000", "0010011000100000", "0000010011100000", "1000110010000000"),
            -- S Tetromino
            ("0110110000000000", "0100011000100000", "0000011011000000", "1000110001000000"),
            -- Z Tetromino
            ("1100011000000000", "0010011001000000", "0000110001100000", "0100110010000000"),
            -- L Tetromino
            ("1000100011000000", "0000011101000000", "0000011000100010", "0000001011100000"),
            -- J Tetromino
            ("0100010011000000", "0100011100000000", "0000001100100010", "0000000011100010")
        );
    begin
        return Tetromino_ROM(block_type, rotation);
    end function;

end package body;


