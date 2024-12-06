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
        led         : out STD_LOGIC_VECTOR(1 downto 0) -- LEDs for output
    --    grid_debug : out std_logic_vector((ROWS * COLS) - 1 downto 0) -- Debug grid output
        -- input_debug : out std_logic -- Debug collision output
    );
end entity;

architecture Behavioral of top_level is

     component input_handler
     Port (
         clk         : in  std_logic; -- Clock signal
         reset       : in  std_logic; -- Reset signal
         raw_left    : in  std_logic; -- Raw left button signal
         raw_right   : in  std_logic; -- Raw right button signal
         raw_rotate  : in  std_logic; -- Raw rotate button signal
         move_left   : out std_logic; -- Debounced left button signal
         move_right  : out std_logic; -- Debounced right button signal
         rotate      : out std_logic;  -- Debounced rotate button signal
         debounced_reset : out std_logic              -- Debounced reset signal (optional)
     );
     end component;

    -- VGA Controller Signals
    signal grid_serialized : std_logic_vector((ROWS * COLS) - 1 downto 0);
    signal tx_signal       : std_logic;

    -- Game Grid
    signal g : Grid := (others => (others => '0')); -- 20x12 game grid

    -- Tetromino Signals
    signal tetromino   : std_logic_vector(0 to 15);               -- Tetromino data
    signal piece_pos_x : integer range 0 to COLS - 1 := COLS / 2 - 1; -- Start X position
    signal piece_pos_y : integer range 0 to ROWS - 1 := 0;            -- Start Y position

    -- Clock Divider for Slow Movement
    signal slow_clk : std_logic;

    signal shadow_grid : Grid := (others => (others => '0'));
    
    signal rotation : integer range 0 to 3 := 0;                -- Default rotation index (0 degrees)
    signal block_type : integer range 0 to 6 := 5;              -- Current tetromino type
    -- signal active_piece : std_logic_vector(0 to 15);        -- Current active piece (shape & rotation)

    -- Internal signals for debounced outputs
     signal debounced_left   : std_logic;
     signal debounced_right  : std_logic;
     signal debounced_rotate : std_logic;
    
    -- signal left_signal : std_logic := '0';
    -- signal right_signal : std_logic := '0';
    -- signal rotate_signal : std_logic := '0';

    -- signal reset_left_signal : std_logic := '0';
    -- signal reset_right_signal : std_logic := '0';
    -- signal reset_rotate_signal : std_logic := '0';

begin

    -- Clock Divider for Slow Movement
    clk_div_inst: entity work.clock_divider
        port map (
            clk_in  => clk,
            reset=> '0',
            clk_out => slow_clk
        );
    
     input_handler_inst: input_handler -- <port being mapped to> => <signal receiving value>
     port map (
         clk             => clk,           -- System clock
         reset           => reset,         -- Reset signal
         raw_left        => raw_left,      -- Raw input for move left
         raw_right       => raw_right,     -- Raw input for move right
         raw_rotate      => raw_rotate,    -- Raw input for rotate
         move_left       => debounced_left, -- Debounced move_left signal
         move_right      => debounced_right, -- Debounced move_right signal
         rotate          => debounced_rotate, -- Debounced rotate signal
         debounced_reset => open            -- Debounced reset signal (optional)       
     );

    -- process (clk)
    -- begin
    --     if rising_edge(clk) then
    --         -- if raw_left = '1' then
    --         if debounced_left = '1' then
    --             left_signal <= '1';
    --             led <= "01";
    --         -- elsif raw_right = '1' then
    --         elsif debounced_right = '1' then
    --             right_signal <= '1';
    --             led <= "10";
    --         -- elsif raw_rotate = '1' then
    --         elsif debounced_rotate = '1' then
    --             rotate_signal <= '1';
    --             led <= "11";
    --         else
    --             led <= "00";
    --             -- do nothing
    --         end if;

    --         if reset_left_signal = '1' then
    --             left_signal <= '0';
    --         elsif reset_right_signal = '1' then
    --             right_signal <= '0';
    --         elsif reset_rotate_signal = '1' then
    --             rotate_signal <= '0';
    --         else
    --             -- do nothing
    --         end if;
    --     end if;
    -- end process;

    -- Main Falling Logic
    falling_logic: process (slow_clk, block_type, piece_pos_x, piece_pos_y, rotation, g, shadow_grid)
        variable temp_piece_pos_x : integer range 0 to COLS - 1 := 0;
        variable temp_piece_pos_y : integer range 0 to ROWS - 1 := 0;
        -- For rotation
        variable temp_rotation : integer range 0 to 3;
        variable rotated_piece : std_logic_vector(0 to 15);

        variable input_state : std_logic_vector(2 downto 0);

        variable flag : std_logic := '0';
        variable new_flag : std_logic := '1';
        variable new_block_flag : std_logic := '1';
    begin
        
        if rising_edge(slow_clk) then
        
        	if flag = '1' then
				flag := '0';
				shadow_grid <= g;
			end if;
        
        	tetromino <= fetch_tetromino(block_type, rotation);

            -- Combine input signals into a single state
            -- input_state := left_signal & right_signal & rotate_signal;
            input_state := debounced_left & debounced_right & debounced_rotate;
            -- input_state := raw_left & raw_right & raw_rotate;

            if new_block_flag = '1' then
                -- do nothing
                new_block_flag := '0';
            else
                if new_flag = '1' then
                    if not collision_detected(piece_pos_x, piece_pos_y, tetromino, shadow_grid) then
                        -- Lock the tetromino into the main grid at the spawn position
                        lock_piece(g, piece_pos_x, piece_pos_y, tetromino);
                        new_flag := '0';
                    else
                        -- game over
                        new_flag := '1';
                    end if;
                else
                    -- Case statement for the combined input state
                    case input_state is
                    when "100" =>
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
                            new_flag := '1';
                            new_block_flag := '1';
                
                            -- Reset the piece position to spawn a new tetromino
                            piece_pos_x <= COLS / 2 - 1; -- Centered spawn
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

                        -- reset_left_signal <= '1';
                        -- reset_right_signal <= '0';
                        -- reset_rotate_signal <= '0';

                    when "010" =>
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
                            new_flag := '1';
                            new_block_flag := '1';
                
                            -- Reset the piece position to spawn a new tetromino
                            piece_pos_x <= COLS / 2 - 1; -- Centered spawn
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

                        -- reset_right_signal <= '1';
                        -- reset_left_signal <= '0';
                        -- reset_rotate_signal <= '0';

                    when "001" =>
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
                                new_flag := '1';
                                new_block_flag := '1';

                                -- Reset the piece position to spawn a new tetromino
                                piece_pos_x <= COLS / 2 - 1; -- Centered spawn
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
                                new_flag := '1';
                                new_block_flag := '1';

                                -- Reset the piece position to spawn a new tetromino
                                piece_pos_x <= COLS / 2 - 1; -- Centered spawn
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

                        -- reset_rotate_signal <= '1';
                        -- reset_left_signal <= '0';
                        -- reset_right_signal <= '0';
                    
                    when others =>
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
                            new_flag := '1';
                            new_block_flag := '1';
                
                            -- Reset the piece position to spawn a new tetromino
                            piece_pos_x <= COLS / 2 - 1; -- Centered spawn
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

                        -- reset_left_signal <= '0';
                        -- reset_right_signal <= '0';
                        -- reset_rotate_signal <= '0';
                    end case;
                end if;
            end if;
        end if;

    end process;


    -- Serialize the grid to pass to VGA controller
    serialize_grid_process: process (clk)
    begin
        if rising_edge(clk) then
            grid_serialized <= serialize_grid(g);
            -- grid_debug <= serialize_grid(g);
            -- input_debug <= input_signal;
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