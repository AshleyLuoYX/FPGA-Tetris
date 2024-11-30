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
    function collision_detected(x : integer; y : integer; piece : std_logic_vector; grid : Grid) return boolean;
    function rotate_piece(piece : std_logic_vector) return std_logic_vector;
    procedure lock_piece(signal g : inout Grid; x : integer; y : integer; piece : std_logic_vector);
    function detect_and_clear_lines(signal g : inout Grid) return integer;
    function serialize_grid(signal g : Grid) return std_logic_vector;

end tetris_utils;

-- Package Body
package body tetris_utils is

    -- Function: Collision Detection
    function collision_detected(
    x      : integer;              -- Top-left x-coordinate of the piece
    y      : integer;              -- Top-left y-coordinate of the piece
    piece  : std_logic_vector(15 downto 0); -- Flattened 4x4 piece matrix
    grid   : Grid                  -- Current game grid
    ) return boolean is
    variable px, py : integer;     -- Piece matrix indices
    variable gx, gy : integer;     -- Grid coordinates
    
    begin
        -- Iterate through the 4x4 matrix of the piece
        for py in 0 to 3 loop
            for px in 0 to 3 loop
                -- Extract the current piece block (1 if occupied, 0 if empty)
                if piece((py * 4) + px) = '1' then
                    -- Compute grid coordinates for the block
                    gx := x + px;       -- Grid x-coordinate
                    gy := y + py;       -- Grid y-coordinate
                    
                    -- Check if block is out of bounds
                    if gx < 0 or gx >= COLS or gy < 0 or gy >= ROWS then
                        return true;    -- Collision detected with the edge
                    end if;

                    -- Check if block overlaps with an existing block in the grid
                    if grid(gy, gx) = '1' then
                        return true;    -- Collision detected with other blocks
                    end if;
                end if;
            end loop;
        end loop;

        -- If no collisions were detected, return false
        return false;
    end function;


    -- -- Function: Rotate Piece (we will hard code this part)
    -- function rotate_piece(piece : std_logic_vector) return std_logic_vector is
    -- begin
    --     -- Implement piece rotation logic here
    --     return piece; -- Placeholder
    -- end function;

    -- Procedure: Lock Piece
    procedure lock_piece(signal g : inout Grid; x : integer; y : integer; piece : std_logic_vector) is
    begin
        -- Implement logic to lock the piece into the grid
    end procedure;

    -- Function: Detect and Clear Lines
    function detect_and_clear_lines(signal g : inout Grid) return integer is
        variable lines_cleared : integer := 0;
    begin
        for row in 0 to ROWS-1 loop
            if g(row) = (others => '1') then
                lines_cleared := lines_cleared + 1;
                -- Shift rows down
                for r in row downto 1 loop
                    g(r) := g(r-1);
                end loop;
                g(0) := (others => '0');
            end if;
        end loop;
        return lines_cleared;
    end function;

    -- Function: Serialize Grid
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
