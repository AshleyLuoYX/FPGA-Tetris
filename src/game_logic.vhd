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

    component clock_divider
        Port (
            clk_in      : in  std_logic;
            reset       : in  std_logic;
            clk_out     : out std_logic
        );
    end component;
    
    -- Internal Signals
    signal slow_clk: std_logic;
    
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
    
    -- Clock Divider Instantiation
    clk_div_inst : clock_divider
        port map (
            clk_in  => clk,       -- Connect to the 12 MHz input clock
            reset   => reset,     -- Connect to the reset signal
            clk_out => slow_clk   -- Slower clock output (1 Hz)
        );
        
    -- Main Game Process
    game_process : process(slow_clk, reset)
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
        elsif rising_edge(slow_clk) then
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
                    block_type <= next_block_type;        -- Get the next block type
                    rotation <= 0;                        -- Initialize rotation to 0° (no rotation)
                    active_piece <= rotate_piece(block_type, 0); -- Fetch the 0° rotated piece using ROM
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
