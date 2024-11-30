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
    signal rotation : integer range 0 to 3 := 1;                -- Default rotation index (90 degrees)
    signal current_score : integer := 0;                        -- Player's score

    -- Function and Procedure Imports
    use work.tetris_utils.ALL;

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
            rotation <= 1;                            -- Default rotation
            current_score <= 0;
            game_over <= '0';
        elsif rising_edge(clk) then
            if game_over = '0' then
                -- Handle Movement
                if move_left = '1' then
                    if not collision_detected(piece_pos_x - 1, piece_pos_y, active_piece, grid) then
                        piece_pos_x <= piece_pos_x - 1;
                    end if;
                elsif move_right = '1' then
                    if not collision_detected(piece_pos_x + 1, piece_pos_y, active_piece, grid) then
                        piece_pos_x <= piece_pos_x + 1;
                    end if;
                end if;

                -- Handle Rotation
                if rotate = '1' then
                    -- Increment rotation and get new rotated piece
                    variable new_rotation : integer range 0 to 3 := (rotation + 1) mod 4;
                    variable rotated_piece : std_logic_vector(15 downto 0);
                    rotated_piece := rotate_piece(block_type, new_rotation);

                    if not collision_detected(piece_pos_x, piece_pos_y, rotated_piece, grid) then
                        active_piece <= rotated_piece; -- Apply the rotation
                        rotation <= new_rotation;     -- Update the rotation index
                    end if;
                end if;

                -- Handle Piece Drop
                if not collision_detected(piece_pos_x, piece_pos_y + 1, active_piece, grid) then
                    piece_pos_y <= piece_pos_y + 1;
                else
                    lock_piece(grid, piece_pos_x, piece_pos_y, active_piece); -- Lock piece in place
                    spawn_new_piece <= '1';
                end if;

                -- Spawn New Piece
                if spawn_new_piece = '1' then
                    block_type <= next_block_type; -- Get next block type
                    rotation <= 1;                -- Default rotation to 90 degrees
                    active_piece <= rotate_piece(next_block_type, 1); -- Get rotated piece
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
