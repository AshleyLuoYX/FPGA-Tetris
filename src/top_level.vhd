library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;

    -- Include the tetris_utils package
    use work.tetris_utils.all;

entity top_level is
    port (
        clk   : in  std_logic;                    -- System clock
        reset : in  std_logic := '0';             -- Reset signal
        red   : out std_logic_vector(1 downto 0); -- VGA red signal
        green : out std_logic_vector(1 downto 0); -- VGA green signal
        blue  : out std_logic_vector(1 downto 0); -- VGA blue signal
        hsync : out std_logic;                    -- Horizontal sync
        vsync : out std_logic;                     -- Vertical sync
        raw_left   : in  std_logic;                  -- Raw input for move left
        raw_right  : in  std_logic;                  -- Raw input for move right
        raw_rotate : in  std_logic;                   -- Raw input for rotate
        led         : out STD_LOGIC_VECTOR(1 downto 0); -- LEDs for output
        grid_debug : out std_logic_vector((20 * 12) - 1 downto 0); -- Debug grid output
        TB_slow_clk      : out std_logic;                    -- Observable slow clock
        TB_divide_count  : out integer;                      -- Observable divide count
        TB_score         : out integer                       -- Observable score
    );
end entity;

architecture Behavioral of top_level is

    -- component input_handler
    -- Port (
    --     clk         : in  std_logic; -- Clock signal
    --     reset       : in  std_logic; -- Reset signal
    --     raw_left    : in  std_logic; -- Raw left button signal
    --     raw_right   : in  std_logic; -- Raw right button signal
    --     raw_rotate  : in  std_logic; -- Raw rotate button signal
    --     move_left   : out std_logic; -- Debounced left button signal
    --     move_right  : out std_logic; -- Debounced right button signal
    --     rotate      : out std_logic;  -- Debounced rotate button signal
    --     debounced_reset : out std_logic              -- Debounced reset signal (optional)
    -- );
    -- end component;

    -- VGA Controller Signals
    signal grid_serialized : std_logic_vector((ROWS * COLS) - 1 downto 0);
    signal tx_signal       : std_logic;

    -- Game Grid
    --signal g : Grid := (others => (others => '0')); -- 20x12 game grid
    signal g : Grid := (
        
        17 => ("001100111111"), 
        18 => (others => '1'),
        19 => ("110011000000"), 
        others => (others => '0') -- All other rows are empty
    );
    
    -- Tetromino Signals
    signal tetromino   : std_logic_vector(0 to 15);               -- Tetromino data
    signal piece_pos_x : integer range 0 to COLS - 1 := COLS / 2 - 2; -- Start X position
    signal piece_pos_y : integer range 0 to ROWS - 1 := 0;            -- Start Y position

    -- Temporary New X and Y Position
    signal new_piece_pos_x : integer range 0 to COLS - 1;
    signal new_piece_pos_y : integer range 0 to ROWS - 1;

    signal shadow_grid : Grid := (others => (others => '0'));
    
    signal rotation : integer range 0 to 3 := 0;                -- Default rotation index (0 degrees)
    signal block_type : integer range 0 to 6 := 5;              -- Current tetromino type
    signal active_piece : std_logic_vector(0 to 15);        -- Current active piece (shape & rotation)

    -- Internal signals for debounced outputs
    -- signal debounced_left   : std_logic;
    -- signal debounced_right  : std_logic;
    -- signal debounced_rotate : std_logic;
    
    signal left_signal : std_logic := '0';
    signal right_signal : std_logic := '0';
    signal rotate_signal : std_logic := '0';

    -- signal reset_left_signal : std_logic := '0';
    -- signal reset_right_signal : std_logic := '0';
    -- signal reset_rotate_signal : std_logic := '0';
    
    
    -- Clock Divider for Slow Movement
    signal slow_clk : std_logic;
    signal current_divide_count : integer := 100; -- Default to 1 Hz
    signal score : integer := 0; -- Score counter
    
    

begin
    -- Map internal signals to output ports
    TB_slow_clk <= slow_clk; -- Expose slow clock
    TB_divide_count <= current_divide_count; -- Expose divide count
    TB_score <= score; -- Expose score
    
    
    -- Clock Divider for Slow Movement
    clk_div_inst: entity work.clock_divider
        port map (
            clk_in  => clk,
            reset=> '0',
            divide_count => current_divide_count,
            clk_out => slow_clk
        );
     
     -- Process to update divide_count based on score
    process (score)
    begin
        -- Scale divide_count based on score
        current_divide_count <= 30 - score*5; -- Example: Decrease divide_count as score increases
        if current_divide_count < 5 then
            current_divide_count <= 5; -- Minimum value
        end if;
    end process;

    
    -- Score Update Logic (Simplified Example)
--    process (slow_clk, reset)
--    begin
--        if reset = '1' then
--            score <= 0; -- Reset score
--        elsif rising_edge(slow_clk) then
--            -- Example: Increment score every slow clock cycle
--            score <= score + 1;
--        end if;
--    end process;
    
    row_clearing_logic: process (clk)
    begin
        if rising_edge(clk) then
            -- Simulate the row-clearing logic
            clear_full_rows(g, score);
    
            -- Serialize the grid for debugging
            grid_debug <= serialize_grid(g);
        end if;
    end process;
    
    -- input_handler_inst: input_handler -- <port being mapped to> => <signal receiving value>
    -- port map (
    --     clk             => clk,           -- System clock
    --     reset           => reset,         -- Reset signal
    --     raw_left        => raw_left,      -- Raw input for move left
    --     raw_right       => raw_right,     -- Raw input for move right
    --     raw_rotate      => raw_rotate,    -- Raw input for rotate
    --     move_left       => debounced_left, -- Debounced move_left signal
    --     move_right      => debounced_right, -- Debounced move_right signal
    --     rotate          => debounced_rotate, -- Debounced rotate signal
    --     debounced_reset => open            -- Debounced reset signal (optional)       
    -- );

--    -- Main Falling Logic
--    falling_logic: process (slow_clk, clk)
--        variable temp_piece_pos_x : integer range 0 to COLS - 1;
--        variable temp_piece_pos_y : integer range 0 to ROWS - 1;
--        -- For rotation
--        variable temp_rotation : integer range 0 to 3;
--        variable rotated_piece : std_logic_vector(0 to 15);

--        variable left_var : std_logic := '0';
--        variable right_var : std_logic := '0';
--        variable rotate_var : std_logic := '0';
--    begin
--        if rising_edge(slow_clk) then
--            tetromino <= fetch_tetromino(block_type, 0);
--            if left_signal = '1' then
--                -- Initialize temporary variables with current signal values
--                temp_piece_pos_x := piece_pos_x;
--                temp_piece_pos_y := piece_pos_y;
        
--                -- Clear the current tetromino from the main grid
--                delete_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
        
--                -- Test move-left animation
--                if not collision_detected(temp_piece_pos_x - 1, temp_piece_pos_y, tetromino, shadow_grid) then
--                    -- Update temporary X position to move left
--                    temp_piece_pos_x := temp_piece_pos_x - 1;
--                end if;
        
--                -- Check for collision below
--                if collision_detected(temp_piece_pos_x, temp_piece_pos_y + 1, tetromino, shadow_grid) then
--                    -- If collision detected, lock the tetromino into the grid
--                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
        
--                    -- Reset the piece position to spawn a new tetromino
--                    piece_pos_x <= COLS / 2 - 2; -- Centered spawn
--                    piece_pos_y <= 0;
--                else
--                    -- Move the tetromino down
--                    temp_piece_pos_y := temp_piece_pos_y + 1;
        
--                    -- Lock the tetromino into the main grid at the new position
--                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
        
--                    -- Assign updated temporary positions back to signals
--                    piece_pos_x <= temp_piece_pos_x;
--                    piece_pos_y <= temp_piece_pos_y;
--                end if;

--                -- Update shadow grid for visualization
--                shadow_grid <= g;
--                -- Clear the tetromino's new position from the shadow grid
--                delete_piece(shadow_grid, temp_piece_pos_x, temp_piece_pos_y, tetromino);

--            elsif right_signal = '1' then
--                -- Initialize temporary variables with current signal values
--                temp_piece_pos_x := piece_pos_x;
--                temp_piece_pos_y := piece_pos_y;
        
--                -- Clear the current tetromino from the main grid
--                delete_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
        
--                -- Test move-left animation
--                if not collision_detected(temp_piece_pos_x + 1, temp_piece_pos_y, tetromino, shadow_grid) then
--                    -- Update temporary X position to move left
--                    temp_piece_pos_x := temp_piece_pos_x + 1;
--                end if;
        
--                -- Check for collision below
--                if collision_detected(temp_piece_pos_x, temp_piece_pos_y + 1, tetromino, shadow_grid) then
--                    -- If collision detected, lock the tetromino into the grid
--                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
        
--                    -- Reset the piece position to spawn a new tetromino
--                    piece_pos_x <= COLS / 2 - 2; -- Centered spawn
--                    piece_pos_y <= 0;
--                else
--                    -- Move the tetromino down
--                    temp_piece_pos_y := temp_piece_pos_y + 1;
        
--                    -- Lock the tetromino into the main grid at the new position
--                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
        
--                    -- Assign updated temporary positions back to signals
--                    piece_pos_x <= temp_piece_pos_x;
--                    piece_pos_y <= temp_piece_pos_y;
--                end if;
--                -- Update shadow grid for visualization
--                shadow_grid <= g;
        
--                -- Clear the tetromino's new position from the shadow grid
--                delete_piece(shadow_grid, temp_piece_pos_x, temp_piece_pos_y, tetromino);

--            elsif rotate_signal = '1' then
--                -- Initialize temporary variables with current signal values
--                temp_piece_pos_x := piece_pos_x;
--                temp_piece_pos_y := piece_pos_y;
--                temp_rotation := rotation;

--                -- Clear the current position of the tetromino from the main grid
--                delete_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);

--                -- Handle Rotation
--                temp_rotation := (rotation + 1) mod 4; -- Increment rotation
--                rotated_piece := rotate_piece(block_type, temp_rotation);

--                if not collision_detected(temp_piece_pos_x, temp_piece_pos_y, rotated_piece, shadow_grid) then
--                    -- Apply rotation if no collision
--                    tetromino <= rotated_piece;
--                    rotation <= temp_rotation;

--                    -- Check for collision below
--                    if collision_detected(temp_piece_pos_x, temp_piece_pos_y + 1, rotated_piece, shadow_grid) then
--                        -- If collision detected, lock the piece into the grid
--                        lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, rotated_piece);

--                        -- Reset the piece position to spawn a new tetromino
--                        piece_pos_x <= COLS / 2 - 2; -- Centered spawn
--                        piece_pos_y <= 0;
--                        rotation <= 0; -- Reset rotation
--                    else
--                        -- Move the tetromino down
--                        temp_piece_pos_y := temp_piece_pos_y + 1;

--                        -- Lock the tetromino into the grid at the new position
--                        lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, rotated_piece);

--                        -- Assign updated temporary positions back to signals
--                        piece_pos_x <= temp_piece_pos_x;
--                        piece_pos_y <= temp_piece_pos_y;
--                    end if;

--                    -- Update shadow grid for visualization
--                    shadow_grid <= g;

--                    -- Clear the tetromino's new position from the shadow grid
--                    delete_piece(shadow_grid, temp_piece_pos_x, temp_piece_pos_y, rotated_piece);

--                else
--                    -- Check for collision below
--                    if collision_detected(temp_piece_pos_x, temp_piece_pos_y + 1, tetromino, shadow_grid) then
--                        -- If collision detected, lock the piece into the grid
--                        lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);

--                        -- Reset the piece position to spawn a new tetromino
--                        piece_pos_x <= COLS / 2 - 2; -- Centered spawn
--                        piece_pos_y <= 0;
--                        rotation <= 0; -- Reset rotation
--                    else
--                        -- Move the tetromino down
--                        temp_piece_pos_y := temp_piece_pos_y + 1;

--                        -- Lock the tetromino into the grid at the new position
--                        lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);

--                        -- Assign updated temporary positions back to signals
--                        piece_pos_x <= temp_piece_pos_x;
--                        piece_pos_y <= temp_piece_pos_y;
--                    end if;

--                    -- Update shadow grid for visualization
--                    shadow_grid <= g;

--                    -- Clear the tetromino's new position from the shadow grid
--                    delete_piece(shadow_grid, temp_piece_pos_x, temp_piece_pos_y, tetromino);
--                end if;

--            else
--                -- Initialize temporary variables with current signal values
--                temp_piece_pos_x := piece_pos_x;
--                temp_piece_pos_y := piece_pos_y;
        
--                -- Clear the current tetromino from the main grid
--                delete_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);

--                -- Check for collision below
--                if collision_detected(temp_piece_pos_x, temp_piece_pos_y + 1, tetromino, shadow_grid) then
--                    -- If collision detected, lock the tetromino into the grid
--                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
        
--                    -- Reset the piece position to spawn a new tetromino
--                    piece_pos_x <= COLS / 2 - 2; -- Centered spawn
--                    piece_pos_y <= 0;
--                else
--                    -- Move the tetromino down
--                    temp_piece_pos_y := temp_piece_pos_y + 1;
        
--                    -- Lock the tetromino into the main grid at the new position
--                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
        
--                    -- Assign updated temporary positions back to signals
--                    piece_pos_x <= temp_piece_pos_x;
--                    piece_pos_y <= temp_piece_pos_y;
--                end if;
--                -- Update shadow grid for visualization
--                shadow_grid <= g;
        
--                -- Clear the tetromino's new position from the shadow grid
--                delete_piece(shadow_grid, temp_piece_pos_x, temp_piece_pos_y, tetromino);

--            end if;

--        elsif falling_edge(slow_clk) then
--            left_var := '0';
--            right_var := '0';
--            rotate_var := '0';

--        elsif rising_edge(clk) then
--            -- if debounced_left = '1' then
--            if raw_left = '1' then
--                left_var := '1';
--            -- elsif debounced_right = '1' then
--            elsif raw_right = '1' then
--                right_var := '1';
--            -- elsif debounced_rotate = '1' then
--            elsif raw_rotate = '1' then
--                rotate_var := '1';
--            else
--                -- do nothing
--            end if;
--            left_signal <= left_var;
--            right_signal <= right_var;
--            rotate_signal <= rotate_var;
--        end if;
--    end process;


    -- Serialize the grid to pass to VGA controller
    serialize_grid_process: process (clk)
    begin
        if rising_edge(clk) then
            grid_serialized <= serialize_grid(g);
            grid_debug <= serialize_grid(g);
        end if;
    end process;

    -- VGA Controller Instance
    vga_ctrl_inst: entity work.vga_controller_simple_tetris
        port map (
            clk   => clk,
            reset => reset,
            tx    => tx_signal,       -- Optional TX signal (unused here)
            grid  => grid_serialized, -- Serialized grid data
            red   => red,             -- VGA red signal
            green => green,           -- VGA green signal
            blue  => blue,            -- VGA blue signal
            hsync => hsync,           -- VGA horizontal sync
            vsync => vsync -- VGA vertical sync
        );

end architecture;
