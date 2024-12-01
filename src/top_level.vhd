library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Include the tetris_utils package
use work.tetris_utils.all;

entity top_level is
    port (
        clk   : in  std_logic;                    -- System clock
        reset : in  std_logic := '0';                    -- Reset signal
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

    -- Tetromino Generation Signals
    signal block_type : integer range 0 to 6 := 5;                           -- Tetromino type (0 to 6)
    signal tetromino  : std_logic_vector(0 to 15);                       -- Tetromino data
    signal grid_in    : Grid := (others => (others => '0'));                 -- Input grid
    signal grid_out   : Grid;                                               -- Updated grid

begin

    -- Tetromino Fetch Process
    tetromino_process: process (clk, reset)
    begin
        if rising_edge(clk) then
            -- Fetch the tetromino
            tetromino <= fetch_tetromino(block_type, 0); -- Always fetch with 0 rotation
        end if;
    end process;

    -- Lock Piece Module Instance
    lock_piece_inst: entity work.lock_piece_module
        port map (
            clk        => clk,
            reset      => reset,
            grid_in    => grid_in,
            start_x    => 2, -- Specify starting X position
            start_y    => 2, -- Specify starting Y position
            tetromino  => tetromino,
            grid_out   => grid_out
        );

    -- Serialize the grid to pass to VGA controller
    process(clk)
    begin
        if rising_edge(clk) then
            grid_serialized <= serialize_grid(grid_out);
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
