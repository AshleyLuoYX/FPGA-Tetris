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

    -- Tetromino Generation Signals
    signal block_type  : integer range 0 to 6 := 0;       -- Tetromino type (0 to 6)
    signal rotation    : integer range 0 to 3 := 0;       -- Rotation (0°, 90°, 180°, 270°)
    signal tetromino   : std_logic_vector(15 downto 0);   -- Tetromino data
    signal grid        : Grid := (others => (others => '0')); -- 2D game grid

begin

    -- Process to Rotate and Display Tetromino
    tetromino_process : process(clk, reset)
    begin
        if reset = '1' then
            -- Reset logic
            block_type <= 0;
            rotation <= 0;
            grid <= (others => (others => '0')); -- Clear the grid
        elsif rising_edge(clk) then
            -- Fetch and Rotate the tetromino
            tetromino <= fetch_tetromino(block_type, rotation);

            -- Clear the grid and place the tetromino in the top-left corner
            grid <= (others => (others => '0'));
            for row in 0 to 3 loop
                for col in 0 to 3 loop
                    if tetromino((row * 4) + col) = '1' then
                        grid(row, col) <= '1'; -- Place the tetromino in the grid
                    end if;
                end loop;
            end loop;

            -- Increment rotation for next frame
            rotation <= (rotation + 1) mod 4;

            -- Change block type after a full rotation cycle
            if rotation = 0 then
                block_type <= (block_type + 1) mod 7;
            end if;
        end if;
    end process;

    -- Serialize the grid to pass to VGA controller
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
