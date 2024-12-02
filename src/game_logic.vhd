library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Function and Procedure Imports
use work.tetris_utils.ALL;

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
            clk_in  : in  std_logic; -- Input clock signal
            reset   : in  std_logic; -- Reset signal
            clk_out : out std_logic  -- Slower output clock signal
        );
    end component;
    
    component random_num
    port (
        clk : in std_logic;
        reset : in std_logic;
        random_number : out std_logic_vector(2 downto 0)
    );
    end component;

    component input_handler
    Port (
        clk         : in  std_logic; -- Clock signal
        reset       : in  std_logic; -- Reset signal
        raw_left    : in  std_logic; -- Raw left button signal
        raw_right   : in  std_logic; -- Raw right button signal
        raw_rotate  : in  std_logic; -- Raw rotate button signal
        move_left   : out std_logic; -- Debounced left button signal
        move_right  : out std_logic; -- Debounced right button signal
        rotate      : out std_logic  -- Debounced rotate button signal
    );
    end component;

    -- Internal Signals
    signal slow_clk : std_logic; -- Slower clock for block movement
    signal debounced_left   : std_logic;
    signal debounced_right  : std_logic;
    signal debounced_rotate : std_logic;

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
    signal rotation : integer range 0 to 3 := 0;                -- Default rotation index (0 degrees)
    signal current_score : integer := 0;                        -- Player's score
    signal block_type : integer range 0 to 6 := 0;              -- Current tetromino type
    signal next_block_type : integer range 0 to 6 := 0;         -- Next tetromino type
    
    -- Signal for Random Number Generator
    signal random_tetromino : std_logic_vector(2 downto 0);

begin

    -- Clock Divider Instantiation
    clk_div_inst : clock_divider
        port map (
            clk_in  => clk,       -- Connect to the input clock
            reset   => reset,     -- Connect to the reset signal
            clk_out => slow_clk   -- Slower clock output for block movement
        );
        
     -- Random Number Generator Instantiation
    random_num_inst : random_num
        port map (
            clk           => clk,                -- Connect to system clock
            reset         => reset,              -- Connect to reset signal
            random_number => random_tetromino    -- Output random number
        );

    -- Input Handler Instantiation
    input_handler_inst : input_handler
    port map (
        clk         => clk,         -- Clock signal
        reset       => reset,       -- Reset signal
        raw_left    => move_left,   -- Map raw input directly
        raw_right   => move_right,  -- Map raw input directly
        raw_rotate  => rotate,      -- Map raw input directly
        move_left   => debounced_left,   -- Internal signal for debounced left
        move_right  => debounced_right,  -- Internal signal for debounced right
        rotate      => debounced_rotate  -- Internal signal for debounced rotate
    );
        
    -- Main Game Process
    -- Main Game Process
    game_process : process(slow_clk, reset)
        -- Declare variables at the start of the process
        variable new_rotation : integer range 0 to 3;
        variable rotated_piece : std_logic_vector(15 downto 0);
    begin
        if reset = '1' then
            -- Reset the game state
            grid <= (others => (others => '0'));
            piece_pos_x <= COLS / 2;
            piece_pos_y <= 0;
            spawn_new_piece <= '1';
            rotation <= 0;
            current_score <= 0;
            game_over <= '0';
        elsif rising_edge(slow_clk) then
            if game_over = '0' then
                -- Handle Movement
                if debounced_left = '1' then
                    if not collision_detected(piece_pos_x - 1, piece_pos_y, active_piece, grid) then
                        piece_pos_x <= piece_pos_x - 1;
                    end if;
                elsif debounced_right = '1' then
                    if not collision_detected(piece_pos_x + 1, piece_pos_y, active_piece, grid) then
                        piece_pos_x <= piece_pos_x + 1;
                    end if;
                end if;
    
                -- Handle Rotation
                if debounced_rotate = '1' then
                    -- Increment rotation and get new rotated piece
                    new_rotation := (rotation + 1) mod 4;
                    rotated_piece := rotate_piece(block_type, new_rotation);
                    
                    if not collision_detected(piece_pos_x, piece_pos_y, rotated_piece, grid) then
                        active_piece <= rotated_piece;
                        rotation <= new_rotation;
                    end if;
                end if;
    
                -- Handle Piece Drop
                if not collision_detected(piece_pos_x, piece_pos_y + 1, active_piece, grid) then
                    piece_pos_y <= piece_pos_y + 1;
                else
                    lock_piece(grid, piece_pos_x, piece_pos_y, active_piece);
                    spawn_new_piece <= '1';
                end if;
    
                -- Spawn New Piece
                if spawn_new_piece = '1' then
                    block_type <= next_block_type;
                    next_block_type <= to_integer(unsigned(random_tetromino));
                    rotation <= 0;
                    active_piece <= rotate_piece(block_type, 0);
                    spawn_new_piece <= '0';
                end if;
    
                -- Line Clearing and Scoring
                current_score <= current_score + detect_and_clear_lines(grid);
            end if;
        end if;
    end process;


    -- Outputs
    board_state <= serialize_grid(grid);
    score <= current_score;

end Behavioral;
