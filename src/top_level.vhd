library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Include the tetris_utils package
use work.tetris_utils.ALL;

entity top_level is
    Port (
        clk       : in  std_logic;                  -- System clock
        reset     : in  std_logic;                  -- Reset signal
        red       : out std_logic_vector(1 downto 0); -- VGA red signal
        green     : out std_logic_vector(1 downto 0); -- VGA green signal
        blue      : out std_logic_vector(1 downto 0); -- VGA blue signal
        hsync     : out std_logic;                 -- Horizontal sync
        vsync     : out std_logic                  -- Vertical sync
    );
end top_level;

architecture Behavioral of top_level is

    -- VGA Controller Signals
    signal grid_serialized : std_logic_vector((ROWS * COLS) - 1 downto 0);
    signal tx_signal       : std_logic;

    -- Hardcoded Grid
    signal grid : Grid := (
        0 => "000000000000",
        1 => "000000000000",
        2 => "000000000000",
        3 => "000000000000",
        4 => "000011000000",
        5 => "000011000000",
        6 => "000000000000",
        7 => "000000000000",
        8 => "000000000000",
        9 => "000000000000",
        10 => "000000000000",
        11 => "000000000000",
        12 => "000000000000",
        13 => "000000000000",
        14 => "000000000000",
        15 => "000000000000",
        16 => "000000000000",
        17 => "000000000000",
        18 => "000000000000",
        19 => "000000000000"
    );

begin

    -- Serialize the hardcoded grid
    grid_serialized <= serialize_grid(grid);

    -- VGA Controller Instance
    vga_ctrl_inst : entity work.vga_controller_tetris
        port map (
            clk    => clk,
            reset  => reset,
            tx     => tx_signal,         -- Optional TX signal (unused here)
            grid   => grid_serialized,   -- Serialized grid data
            red    => red,               -- VGA red signal
            green  => green,             -- VGA green signal
            blue   => blue,              -- VGA blue signal
            hsync  => hsync,             -- VGA horizontal sync
            vsync  => vsync              -- VGA vertical sync
        );

end Behavioral;
