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

    function rotate_piece(
        block_type : integer range 0 to 6; rotation : integer range 0 to 3
    ) return std_logic_vector;

    procedure lock_piece(
        signal g : inout Grid; x : integer; y : integer; piece : std_logic_vector
    );

    function detect_and_clear_lines(signal g : inout Grid) return integer;
    function serialize_grid(signal g : Grid) return std_logic_vector;

end tetris_utils;

-- Package Body
package body tetris_utils is

    -- Collision Detection Function
    function collision_detected(
        x : integer; y : integer; piece : std_logic_vector; grid : Grid
    ) return boolean is
    variable px, py, gx, gy : integer;
    begin
        for py in 0 to 3 loop
            for px in 0 to 3 loop
                if piece((py * 4) + px) = '1' then
                    gx := x + px;
                    gy := y + py;
                    if gx < 0 or gx >= COLS or gy < 0 or gy >= ROWS then
                        return true;
                    end if;
                    if grid(gy, gx) = '1' then
                        return true;
                    end if;
                end if;
            end loop;
        end loop;
        return false;
    end function;

    -- Rotate Piece Function
    function rotate_piece(
        block_type : integer range 0 to 6; rotation : integer range 0 to 3
    ) return std_logic_vector is
    variable rotated_piece : std_logic_vector(15 downto 0);
    begin
        -- Fetch from ROM (assumed to be instantiated elsewhere)
        rotated_piece := fetch_tetromino(block_type, rotation);
        return rotated_piece;
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

    -- Line Clearing Function
    function detect_and_clear_lines(signal g : inout Grid) return integer is
        variable lines_cleared : integer := 0;
    begin
        for row in 0 to ROWS-1 loop
            if g(row) = (others => '1') then
                lines_cleared := lines_cleared + 1;
                for r in row downto 1 loop
                    g(r) := g(r-1);
                end loop;
                g(0) := (others => '0');
            end if;
        end loop;
        return lines_cleared;
    end function;

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
