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
    signal tetromino   : std_logic_vector(15 downto 0); -- Tetromino data (4x4 matrix)
    signal piece_pos_x : integer range 0 to COLS - 1 := COLS / 2 - 2; -- Start X position
    signal piece_pos_y : integer range 0 to ROWS - 1 := 0;            -- Start Y position

    -- Updated Positions
    signal updated_x : integer range 0 to COLS - 1;
    signal updated_y : integer range 0 to ROWS - 1;

    -- Updated Grid Signal
    signal updated_grid : Grid;

    -- Clock Divider for Slow Movement
    signal slow_clk : std_logic;

begin

    -- Clock Divider for Slow Movement
    clk_div_inst: entity work.clock_divider
        port map (
            clk_in  => clk,
            reset   => '0',
            clk_out => slow_clk
        );

    -- Fetch Tetromino Process
    tetromino_fetch: process (slow_clk, reset)
    begin
        if rising_edge(slow_clk) then
            -- Keep the same tetromino for this test
            tetromino <= fetch_tetromino(4, 0);
        end if;
    end process;

    -- Falling Logic using update_piece_loc
    falling_logic_inst: entity work.update_piece_loc
        port map (
            clk        => slow_clk,
            reset      => reset,
            grid_in    => g,
            current_x  => piece_pos_x,
            current_y  => piece_pos_y,
            tetromino  => tetromino,
            move_left  => '0', -- No horizontal movement for this test
            move_right => '0', -- No horizontal movement for this test
            rotate     => '0', -- No rotation for this test
            move_down  => '1', -- Falling movement enabled
            block_type => 4,   -- Fixed block type
            rotation   => open, -- Not used in this simple test
            grid_out   => updated_grid,
            new_x      => updated_x,
            new_y      => updated_y
        );

    -- Update the game grid and piece positions
    update_grid_and_position: process(slow_clk, reset)
    begin
        if rising_edge(slow_clk) then
            g <= updated_grid;                -- Update the grid with new piece location
            piece_pos_x <= updated_x;         -- Update X position
            piece_pos_y <= updated_y;         -- Update Y position
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
            vsync => vsync            -- VGA vertical sync
        );

end architecture;
