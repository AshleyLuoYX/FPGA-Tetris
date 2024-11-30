library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Package Declaration
package tetris_utils is

    -- Constants
    constant ROWS : integer := 20;                -- Number of rows in the grid
    constant COLS : integer := 12;                -- Number of columns in the grid

    -- Types
    type Grid is array (0 to ROWS-1, 0 to COLS-1) of std_logic;

    -- Function Declarations
    function collision_detected(
        x : integer; y : integer; piece : std_logic_vector; grid : Grid
    ) return boolean;

    function fetch_tetromino(
        block_type : integer range 0 to 6; rotation : integer range 0 to 3
    ) return std_logic_vector;

    procedure lock_piece(
        signal g : inout Grid; x : integer; y : integer; piece : std_logic_vector
    );

    function serialize_grid(signal g : Grid) return std_logic_vector;

end tetris_utils;

-- Package Body
package body tetris_utils is

    -- Collision Detection Function
    function collision_detected(
        x : integer; y : integer; piece : std_logic_vector; grid : Grid
    ) return boolean is
    begin
        -- Collision detection logic here
        return false; -- Simplified for illustration
    end function;

    -- Fetch Tetromino Function
    function fetch_tetromino(
        block_type : integer range 0 to 6; rotation : integer range 0 to 3
    ) return std_logic_vector is
        -- ROM Data for Tetromino Shapes
        type rom_type is array (0 to 6, 0 to 3) of std_logic_vector(15 downto 0);
        constant Tetromino_ROM : rom_type := (
                -- I Tetromino
            ("0100010001000100", "0000111100000000", "0010001000100010", "0000000011110000"),
            -- O Tetromino
            ("1100110000000000", "0011001100000000", "0000000000110011", "0000000011001100"),
            -- T Tetromino
            ("1110010000000000", "0001001100010000", "0000000000100111", "0000100011001000"),
            -- S Tetromino
            ("0110110000000000", "0010001100010000", "0000000000110110", "0000100011000100"),
            -- Z Tetromino
            ("1100011000000000", "0001001100100000", "0000000001100011", "0000010011001000"),
            -- L Tetromino
            ("0000100010001100", "1110100000000000", "0011000100010000", "0000000000010111"),
            -- J Tetromino
            ("0000000100010011", "0000000010001110", "1100100010000000", "0111000100000000")
        );
    begin
        return Tetromino_ROM(block_type, rotation);
    end function;

    -- Lock Piece Procedure
    procedure lock_piece(signal g : inout Grid; x : integer; y : integer; piece : std_logic_vector) is
    begin
        for py in 0 to 3 loop
            for px in 0 to 3 loop
                if piece((py * 4) + px) = '1' then
                    g(y + py, x + px) <= '1';
                end if;
            end loop;
        end loop;
    end procedure;

    -- Serialize Grid Function
    function serialize_grid(signal g : Grid) return std_logic_vector is
        variable serialized : std_logic_vector((ROWS * COLS) - 1 downto 0);
    begin
        for row in 0 to ROWS-1 loop
            for col in 0 to COLS-1 loop
                serialized((row * COLS) + col) := g(row, col);
            end loop;
        end loop;
        return serialized;
    end function;

end tetris_utils;
