library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;

    -- Include the tetris_utils package
    use work.tetris_utils.all;
    use work.clock_divider;
    use work.random_num;
    use work.debounce;
    use work.grid_bram;
    

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
        raw_drop   : in std_logic;                    -- Raw input for drop function
        restart_game : in std_logic;                  -- Onboard button (btn[0]) for restart
        led         : out STD_LOGIC_VECTOR(1 downto 0) -- LEDs for output
--        grid_debug : out std_logic_vector((20 * 12) - 1 downto 0); -- Debug grid output
--        TB_slow_clk      : out std_logic;                    -- Observable slow clock
--        TB_divide_count  : out integer;                      -- Observable divide count
--        TB_score         : out integer;                       -- Observable score
--        TB_random_tetromino : out integer;
--        TB_block_type : out integer;
--        TB_temp_drop_y  : out integer
    );
end entity;

architecture Behavioral of top_level is

    -- VGA Controller Signals
    signal grid_serialized : std_logic_vector((ROWS * COLS) - 1 downto 0);
    signal tx_signal       : std_logic;

    -- Game Grid
--     signal g :  := (others => (others => '0')); -- 20x12 game grid
    signal g : BRAM_Memory := (others => (others => '0')); 
    
    -- BRAM Interface Signals for Grid
    signal bram_addr   : integer range 0 to ROWS - 1;
    signal bram_data_in  : std_logic_vector(COLS - 1 downto 0);
    signal bram_data_out : std_logic_vector(COLS - 1 downto 0);
    signal bram_we     : std_logic := '0';
        
    -- Tetromino Signals
    signal tetromino   : std_logic_vector(0 to 15);               -- Tetromino data
    signal piece_pos_x : integer range 0 to COLS - 1 := COLS / 2 - 2; -- Start X position
    signal piece_pos_y : integer range 0 to ROWS - 1 := 0;            -- Start Y position

    signal shadow_grid : BRAM_Memory := (others => (others => '0'));
    
    signal rotation : integer range 0 to 3 := 0;                -- Default rotation index (0 degrees)
    signal block_type : integer range 0 to 6 := 6;              -- Current tetromino type
    --signal active_piece : std_logic_vector(0 to 15);        -- Current active piece (shape & rotation)
    
    -- Clock Divider for Slow Movement
    signal slow_clk : std_logic;
    signal current_divide_count : integer := 6_000_000; -- Default to 1 Hz
    signal score : integer := 0; -- Score counter
    
    signal game_over : std_logic := '0'; -- Game over signal, '0': Idle, '1': Playing
    signal random_tetromino : integer;
    
    -- Internal signals for debounced outputs
     signal debounced_left   : std_logic;
     signal debounced_right  : std_logic;
     signal debounced_rotate : std_logic;
     signal debounced_drop   : std_logic;

    signal drop_y: integer range 0 to ROWS - 1 := 0;
begin
--    -- Map internal signals to output ports
--    TB_slow_clk <= slow_clk; -- Expose slow clock
--    TB_divide_count <= current_divide_count; -- Expose divide count
--    TB_score <= score; -- Expose score
--    TB_random_tetromino <= random_tetromino;
--    TB_block_type <= block_type;
    
    -- Clock Divider for Slow Movement
    clk_div_inst: entity work.clock_divider
        port map (
            clk_in  => clk,
            reset=> '0',
            divide_count => current_divide_count,
            clk_out => slow_clk
        );
     
     -- Clock Divider for Slow Movement
    rand_num_inst: entity work.random_num
        port map (
            clk => slow_clk,
            reset => '0',
            random_number => random_tetromino
        );
        
        
     -- Process to update divide_count based on score
    process (score)
    begin
        -- Scale divide_count based on score
        current_divide_count <= 6_000_000 - score*1_000_000; -- Example: Decrease divide_count as score increases
        if current_divide_count < 1000 then
            current_divide_count <= 1000; -- Minimum value
        end if;
    end process;

    debounce_inst: entity work.debounce
        port map (
            clk   => clk,                -- System clock
            btn_r => raw_left,           -- Raw input for move left
            btn_b => raw_right,          -- Raw input for move right
            btn_y => raw_rotate,         -- Raw input for rotate
            btn_g => raw_drop,              -- Reset signal
            out_r => debounced_left,     -- Debounced move_left signal
            out_b => debounced_right,    -- Debounced move_right signal
            out_y => debounced_rotate,   -- Debounced rotate signal
            out_g => debounced_drop                -- Open if reset debounce isn't needed
        );
        
    -- BRAM Instance for Game Grid
    grid_bram_inst: entity work.grid_bram
        generic map (
            ROWS => ROWS, -- Match the ROWS constant from your top_level
            COLS => COLS  -- Match the COLS constant from your top_level
        )
        port map (
            clk       => clk,           -- Connect to the system clock
            addr      => bram_addr,     -- Address input for BRAM
            data_in   => bram_data_in,  -- Data input for write operation
            data_out  => bram_data_out, -- Data output for read operation
            we        => bram_we        -- Write enable signal
        );
    

    -- Main Falling Logic
    falling_logic: process (slow_clk, block_type, piece_pos_x, piece_pos_y, rotation, g, shadow_grid)
        variable temp_piece_pos_x : integer range 0 to COLS - 1 := 0;
        variable temp_piece_pos_y : integer range 0 to ROWS - 1 := 0;
        variable temp_drop_y : integer range 0 to ROWS - 1;
        -- For rotation
        variable temp_rotation : integer range 0 to 3;
        variable rotated_piece : std_logic_vector(0 to 15);

        variable input_state : std_logic_vector(3 downto 0);

        variable flag : std_logic := '0';
        variable new_flag : std_logic := '0';
        variable new_block_flag : std_logic := '1';
    begin
        
        if rising_edge(slow_clk) then
            if game_over = '0' then
                if restart_game = '1' then
                    -- Reset game components
                    g <= (others => (others => '0')); -- Clear the grid
                    shadow_grid <= (others => (others => '0')); -- Clear shadow grid
                    piece_pos_x <= COLS / 2 - 2; -- Reset piece position
                    piece_pos_y <= 0;
                    rotation <= 0;
                    block_type <= random_tetromino; -- Generate new piece
                    score <= 0; -- Reset score
                    game_over <= '1'; -- Start playing
                 else 
                    -- IDLE state, do nothing
                 end if;
            else -- if game_over = '1', start playing
            
                if flag = '1' then
                    flag := '0';
                    shadow_grid <= g;
                end if;
            
                tetromino <= fetch_tetromino(block_type, rotation);
    
                -- Combine input signals into a single state
                -- input_state := left_signal & right_signal & rotate_signal;
                 input_state := debounced_left & debounced_right & debounced_rotate & debounced_drop;
    --            input_state := raw_left & raw_right & raw_rotate & raw_drop;
    
                if new_block_flag = '1' then
                    -- do nothing
                    new_block_flag := '0';
                else
                    if new_flag = '0' then
                         if not collision_detected(piece_pos_x, piece_pos_y, tetromino, shadow_grid) then
                            -- Lock the tetromino into the main grid at the spawn position
                            lock_piece(g, piece_pos_x, piece_pos_y, tetromino);
                            new_flag := '1';
                         else
                            -- game over
                            new_flag := '0';
                            led <= "11";
                            game_over <= '0'; -- enter game_over idle state
                         end if;
                    else
                        -- Case statement for the combined input state
                        case input_state is
                        -- gravity drop logic
                        when "0001" =>                     
    --                        led <= "11";
                            bram_we <= '1';
                            -- Initialize temporary variables with current signal values
                            temp_piece_pos_x := piece_pos_x;
                            temp_piece_pos_y := piece_pos_y;
                          
                    
                            -- if temp_piece_pos_y /= 0 then
                                -- Clear the current tetromino from the main grid
                                delete_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
                            -- end if;
                            
                            temp_drop_y := calculate_drop_y(temp_piece_pos_x, temp_piece_pos_y, block_type, rotation, shadow_grid);
    
                            -- Check for collision below
                            if collision_detected(temp_piece_pos_x, temp_piece_pos_y + 1, tetromino, shadow_grid) then
                                if temp_piece_pos_y /= 0 then
    
                                    -- If collision detected, lock the tetromino into the grid
                                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
    
                                end if;
    
                                flag := '1';
                                new_flag := '0';
                                new_block_flag := '1';
                    
                                -- Reset the piece position to spawn a new tetromino
                                clear_full_rows(g, score);
                                block_type <= random_tetromino;
                                piece_pos_x <= COLS / 2 - 2; -- Centered spawn
                                piece_pos_y <= 0;
                                rotation <= 0; -- Reset rotation
                                tetromino <= fetch_tetromino(block_type, 0);
                            else
                                -- Move the tetromino down
                                temp_piece_pos_y := temp_drop_y;
                                
                                -- Lock the tetromino into the main grid at the new position
                                lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
                    
                                -- Assign updated temporary positions back to signals
                                piece_pos_x <= temp_piece_pos_x;
                                piece_pos_y <= temp_piece_pos_y;
                            end if;
                            bram_we <= '0';
    
                    
                        -- Move left logic
                        when "1000" =>
                            bram_we <= '1';
                            led <= "10";
                            -- Initialize temporary variables with current signal values
                            temp_piece_pos_x := piece_pos_x;
                            temp_piece_pos_y := piece_pos_y;
    
                            -- if temp_piece_pos_y /= 0 then
                                -- Clear the current tetromino from the main grid
                                delete_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
                            -- end if;
                    
                            -- Test move-left animation
                            if not collision_detected(temp_piece_pos_x - 1, temp_piece_pos_y, tetromino, shadow_grid) then
                                -- Update temporary X position to move left
                                temp_piece_pos_x := temp_piece_pos_x - 1;
                            end if;
                    
                            -- Check for collision below
                            if collision_detected(temp_piece_pos_x, temp_piece_pos_y + 1, tetromino, shadow_grid) then
                                if temp_piece_pos_y /= 0 then
    
                                    -- If collision detected, lock the tetromino into the grid
                                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
    
                                end if;
    
                                flag := '1';
                                new_flag := '0';
                                new_block_flag := '1';
                    
                                -- Reset the piece position to spawn a new tetromino
                                clear_full_rows(g, score);
                                block_type <= random_tetromino;
                                piece_pos_x <= COLS / 2 - 2; -- Centered spawn
                                piece_pos_y <= 0;
                                rotation <= 0; -- Reset rotation
                                tetromino <= fetch_tetromino(block_type, 0);
                            else
                                -- Move the tetromino down
                                temp_piece_pos_y := temp_piece_pos_y + 1;
                    
                                -- Lock the tetromino into the main grid at the new position
                                lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
                    
                                -- Assign updated temporary positions back to signals
                                piece_pos_x <= temp_piece_pos_x;
                                piece_pos_y <= temp_piece_pos_y;
                            end if;
                            bram_we <= '0';
                            
                        -- Move right logic
                        when "0100" =>
                            bram_we <= '1';
                            -- Initialize temporary variables with current signal values
                            temp_piece_pos_x := piece_pos_x;
                            temp_piece_pos_y := piece_pos_y;
                    
                            -- if temp_piece_pos_y /= 0 then
                                -- Clear the current tetromino from the main grid
                                delete_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
                            -- end if;
                    
                            -- Test move-left animation
                            if not collision_detected(temp_piece_pos_x + 1, temp_piece_pos_y, tetromino, shadow_grid) then
                                -- Update temporary X position to move left
                                temp_piece_pos_x := temp_piece_pos_x + 1;
                            end if;
                    
                            -- Check for collision below
                            if collision_detected(temp_piece_pos_x, temp_piece_pos_y + 1, tetromino, shadow_grid) then
                                if temp_piece_pos_y /= 0 then
    
                                    -- If collision detected, lock the tetromino into the grid
                                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
    
                                end if;
    
                                flag := '1';
                                new_flag := '0';
                                new_block_flag := '1';
                    
                                -- Reset the piece position to spawn a new tetromino
                                clear_full_rows(g, score);
                                block_type <= random_tetromino;
                                piece_pos_x <= COLS / 2 - 2; -- Centered spawn
                                piece_pos_y <= 0;
                                rotation <= 0; -- Reset rotation
                                tetromino <= fetch_tetromino(block_type, 0);
                            else
                                -- Move the tetromino down
                                temp_piece_pos_y := temp_piece_pos_y + 1;
                    
                                -- Lock the tetromino into the main grid at the new position
                                lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
                    
                                -- Assign updated temporary positions back to signals
                                piece_pos_x <= temp_piece_pos_x;
                                piece_pos_y <= temp_piece_pos_y;
                            end if;
                            bram_we <= '0';
    
                            
                        -- Rotate logic
                        when "0010" =>
                            bram_we <= '1';
                            -- Initialize temporary variables with current signal values
                            temp_piece_pos_x := piece_pos_x;
                            temp_piece_pos_y := piece_pos_y;
                            temp_rotation := rotation;
    
                            -- if temp_piece_pos_y /= 0 then
                                -- Clear the current tetromino from the main grid
                                delete_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
                            -- end if;
    
                            -- Handle Rotation
                            temp_rotation := (rotation + 1) mod 4; -- Increment rotation
                            rotated_piece := rotate_piece(block_type, temp_rotation);
    
                            if not collision_detected(temp_piece_pos_x, temp_piece_pos_y, rotated_piece, shadow_grid) then
                                -- Apply rotation if no collision
                                tetromino <= rotated_piece;
                                rotation <= temp_rotation;
    
                                -- Check for collision below
                                if collision_detected(temp_piece_pos_x, temp_piece_pos_y + 1, rotated_piece, shadow_grid) then
                                    if temp_piece_pos_y /= 0 then
    
                                        -- If collision detected, lock the tetromino into the grid
                                        lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, rotated_piece);
    
                                    end if;
    
                                    flag := '1';
                                    new_flag := '0';
                                    new_block_flag := '1';
    
                                    -- Reset the piece position to spawn a new tetromino
                                    clear_full_rows(g, score);
                                    block_type <= random_tetromino;
                                    piece_pos_x <= COLS / 2 - 2; -- Centered spawn
                                    piece_pos_y <= 0;
                                    rotation <= 0; -- Reset rotation
                                    tetromino <= fetch_tetromino(block_type, 0);
                                else
                                    -- Move the tetromino down
                                    temp_piece_pos_y := temp_piece_pos_y + 1;
    
                                    -- Lock the tetromino into the grid at the new position
                                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, rotated_piece);
    
                                    -- Assign updated temporary positions back to signals
                                    piece_pos_x <= temp_piece_pos_x;
                                    piece_pos_y <= temp_piece_pos_y;
                                end if;
    
                            else
                                -- input_signal <= '0';
                                -- Check for collision below
                                if collision_detected(temp_piece_pos_x, temp_piece_pos_y + 1, tetromino, shadow_grid) then
                                    if temp_piece_pos_y /= 0 then
    
                                        -- If collision detected, lock the tetromino into the grid
                                        lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
    
                                    end if;
    
                                    flag := '1';
                                    new_flag := '0';
                                    new_block_flag := '1';
    
                                    -- Reset the piece position to spawn a new tetromino
                                    clear_full_rows(g, score);
                                    block_type <= random_tetromino;
                                    piece_pos_x <= COLS / 2 - 2; -- Centered spawn
                                    piece_pos_y <= 0;
                                    rotation <= 0; -- Reset rotation
                                    tetromino <= fetch_tetromino(block_type, 0);
                                else
                                    -- Move the tetromino down
                                    temp_piece_pos_y := temp_piece_pos_y + 1;
    
                                    -- Lock the tetromino into the grid at the new position
                                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
    
                                    -- Assign updated temporary positions back to signals
                                    piece_pos_x <= temp_piece_pos_x;
                                    piece_pos_y <= temp_piece_pos_y;
                                end if;
                            end if;
                            bram_we <= '0';
                            
                        
                        when others =>
                            bram_we <= '1';
    --                        led <= "00";
                            -- Initialize temporary variables with current signal values
                            temp_piece_pos_x := piece_pos_x;
                            temp_piece_pos_y := piece_pos_y;
                    
                            -- if temp_piece_pos_y /= 0 then
                                -- Clear the current tetromino from the main grid
                                delete_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
                            -- end if;
    
                            -- Check for collision below
                            if collision_detected(temp_piece_pos_x, temp_piece_pos_y + 1, tetromino, shadow_grid) then
                                if temp_piece_pos_y /= 0 then
    
                                    -- If collision detected, lock the tetromino into the grid
                                    lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
    
                                end if;
    
                                flag := '1';
                                new_flag := '0';
                                new_block_flag := '1';
                    
                                -- Reset the piece position to spawn a new tetromino
                                clear_full_rows(g, score);
                                block_type <= random_tetromino;
                                piece_pos_x <= COLS / 2 - 2; -- Centered spawn
                                piece_pos_y <= 0;
                                rotation <= 0; -- Reset rotation
                                tetromino <= fetch_tetromino(block_type, 0);
                            else
                                -- Move the tetromino down
                                temp_piece_pos_y := temp_piece_pos_y + 1;
                                
                                -- Lock the tetromino into the main grid at the new position
                                lock_piece(g, temp_piece_pos_x, temp_piece_pos_y, tetromino);
                    
                                -- Assign updated temporary positions back to signals
                                piece_pos_x <= temp_piece_pos_x;
                                piece_pos_y <= temp_piece_pos_y;
                            end if;
                            bram_we <= '0';
                        end case;
                    end if;
                end if;
            end if;
        end if;

    end process;


    -- Serialize the grid to pass to VGA controller
    serialize_grid_process: process (clk)
    begin
        if rising_edge(clk) then
            if game_over = '1' then
                grid_serialized <= serialize_bram(g); -- Serialize grid when playing
            else
                grid_serialized <= (others => '0'); -- Blank grid during idle
            end if;
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
