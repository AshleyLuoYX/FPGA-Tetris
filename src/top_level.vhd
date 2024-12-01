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
        vsync : out std_logic                     -- Vertical sync
    );
end entity;

architecture Behavioral of top_level is

    -- VGA Controller Signals
    signal grid_serialized : std_logic_vector((ROWS * COLS) - 1 downto 0);
    signal tx_signal       : std_logic;

    -- Game Grid
    signal g : Grid := (others => (others => '0')); -- 20x12 game grid

    -- Tetromino Signals
    signal tetromino   : std_logic_vector(0 to 15);               -- Tetromino data
    signal piece_pos_x : integer range 0 to COLS - 1 := COLS / 2 - 2; -- Start X position
    signal piece_pos_y : integer range 0 to ROWS - 1 := 0;            -- Start Y position

    -- Clock Divider for Slow Movement
    signal slow_clk : std_logic;

begin

    -- Clock Divider for Slow Movement
    clk_div_inst: entity work.clock_divider
        port map (
            clk_in  => clk,
            reset=> reset,
            clk_out => slow_clk
        );

    -- Fetch Tetromino Process

    tetromino_fetch: process (slow_clk)
    begin
        if rising_edge(slow_clk) then
            if piece_pos_y = 0 and g(piece_pos_y, piece_pos_x) = '0' then
                -- Fetch a new tetromino at the start position
                tetromino <= fetch_tetromino(0, 0); -- Fetch a specific tetromino (e.g., type 0, no rotation)
            end if;
        end if;
    end process;

    -- Main Falling Logic

    falling_logic: process (slow_clk)
    begin
        if rising_edge(slow_clk) then
            -- Check for collision
            -- if collision_detected(piece_pos_x, piece_pos_y + 1, tetromino, g) then
            --     -- If collision detected, lock the piece into the grid
            --     lock_piece(g, piece_pos_x, piece_pos_y, tetromino);

            --     -- Reset the piece position to spawn a new piece
            --     piece_pos_x <= COLS / 2 - 2;
            --     piece_pos_y <= 0;
            -- else
                -- If no collision, move the piece down
                piece_pos_y <= piece_pos_y + 1;
                lock_piece(g, piece_pos_x, piece_pos_y, tetromino);
            -- end if;
        end if;
    end process;

    -- Serialize the grid to pass to VGA controller
    serialize_grid_process: process (clk)
    begin
        if rising_edge(clk) then
            grid_serialized <= serialize_grid(g);
        end if;
    end process;

    -- VGA Controller Instance
    vga_ctrl_inst: entity work.vga_controller_tetris
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
