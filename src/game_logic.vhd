library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_logic is
    Port (
        clk         : in  std_logic;                  -- Clock signal
        reset       : in  std_logic;                  -- Reset signal
        move_left   : in  std_logic;                  -- Move piece left
        move_right  : in  std_logic;                  -- Move piece right
        rotate      : in  std_logic;                  -- Rotate piece
        board_state : out std_logic_vector(479 downto 0); -- Serialized game board (20x12 grid)
        score       : out integer;                    -- Player's score
        game_over   : out std_logic                   -- Game over signal
    );
end game_logic;

architecture Behavioral of game_logic is

    -- Constants
    constant ROWS : integer := 20;                   -- Number of rows in the grid
    constant COLS : integer := 12;                   -- Number of columns in the grid

    -- Types and Signals
    type Grid is array (0 to ROWS-1, 0 to COLS-1) of std_logic; -- Game grid
    signal grid : Grid := (others => (others => '0'));          -- Current game grid
    signal active_piece : std_logic_vector(15 downto 0);        -- Current active piece (shape & rotation)
    signal piece_pos_x : integer range 0 to COLS-1;             -- X position of the active piece
    signal piece_pos_y : integer range 0 to ROWS-1;             -- Y position of the active piece
    signal spawn_new_piece : std_logic := '1';                  -- Flag to spawn a new piece
    signal current_score : integer := 0;                        -- Player's score

    -- Helper Functions
    function collision_detected(x : integer; y : integer; piece : std_logic_vector) return boolean is
        -- Checks if the piece at position (x, y) collides with the grid
    begin
        -- Implement collision detection logic
        return false; -- Placeholder
    end function;

    function rotate_piece(piece : std_logic_vector) return std_logic_vector is
        -- Rotates the piece 90 degrees
    begin
        -- Implement rotation logic
        return piece; -- Placeholder
    end function;

    procedure lock_piece(signal g : inout Grid; x : integer; y : integer; piece : std_logic_vector) is
        -- Locks the piece into the grid
    begin
        -- Implement logic to place piece in the grid
    end procedure;

    function detect_and_clear_lines(signal g : inout Grid) return integer is
        -- Detects and clears full lines, returns the number of lines cleared
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

begin

    -- Main Game Process
    game_process : process(clk, reset)
    begin
        if reset = '1' then
            -- Reset the game state
            grid <= (others => (others => '0'));       -- Clear the grid
            piece_pos_x <= COLS / 2;                  -- Center piece
            piece_pos_y <= 0;                         -- Top of the grid
            spawn_new_piece <= '1';
            current_score <= 0;
            game_over <= '0';
        elsif rising_edge(clk) then
            if game_over = '0' then
                -- Handle Movement
                if move_left = '1' then
                    if not collision_detected(piece_pos_x - 1, piece_pos_y, active_piece) then
                        piece_pos_x <= piece_pos_x - 1;
                    end if;
                elsif move_right = '1' then
                    if not collision_detected(piece_pos_x + 1, piece_pos_y, active_piece) then
                        piece_pos_x <= piece_pos_x + 1;
                    end if;
                end if;

                -- Handle Rotation
                if rotate = '1' then
                    if not collision_detected(piece_pos_x, piece_pos_y, rotate_piece(active_piece)) then
                        active_piece <= rotate_piece(active_piece);
                    end if;
                end if;

                -- Handle Piece Drop (Automatic or Manual)
                if not collision_detected(piece_pos_x, piece_pos_y + 1, active_piece) then
                    piece_pos_y <= piece_pos_y + 1;
                else
                    lock_piece(grid, piece_pos_x, piece_pos_y, active_piece);
                    spawn_new_piece <= '1';
                end if;

                -- Spawn New Piece
                if spawn_new_piece = '1' then
                    -- Logic to spawn a new piece and check for game over
                    spawn_new_piece <= '0';
                end if;

                -- Line Clearing and Scoring
                variable cleared_lines : integer := detect_and_clear_lines(grid);
                current_score <= current_score + cleared_lines;

            end if;
        end if;
    end process;

    -- Outputs
    board_state <= serialize_grid(grid);
    score <= current_score;

end Behavioral;
