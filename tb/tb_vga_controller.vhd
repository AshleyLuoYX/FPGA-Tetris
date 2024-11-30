library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tetris_vga_test is
    Port (
        clk       : in  std_logic;               -- System clock
        reset     : in  std_logic;               -- Reset signal
        red       : out std_logic_vector(1 downto 0); -- VGA red signal
        green     : out std_logic_vector(1 downto 0); -- VGA green signal
        blue      : out std_logic_vector(1 downto 0); -- VGA blue signal
        hsync     : out std_logic;              -- VGA horizontal sync
        vsync     : out std_logic               -- VGA vertical sync
    );
end tetris_vga_test;

architecture Behavioral of tetris_vga_test is
    -- Signals for VGA controller
    signal pixel_x, pixel_y : integer range 0 to 639 := 0;
    signal display_area     : std_logic;

    -- Clock Divider for VGA
    signal clk_vga          : std_logic := '0';
    constant CLK_DIVIDER    : integer := 1; -- Adjust for VGA clock (25.175 MHz)
    signal clk_counter      : integer range 0 to CLK_DIVIDER - 1 := 0;

begin
    -- VGA clock generation
    process(clk)
    begin
        if rising_edge(clk) then
            if clk_counter < CLK_DIVIDER - 1 then
                clk_counter <= clk_counter + 1;
            else
                clk_counter <= 0;
                clk_vga <= not clk_vga; -- Toggle VGA clock
            end if;
        end if;
    end process;

    -- Instantiate VGA controller
    uut_vga_controller : entity work.vga_controller_tetris
        port map (
            clk       => clk_vga,
            reset     => reset,
            tx        => open,       -- TX output not used in this test
            hsync     => hsync,
            vsync     => vsync,
            red       => open,       -- RGB signals driven directly here
            green     => open,
            blue      => open
        );

    -- Simplified RGB Pattern (Static Display)
    process(pixel_x, pixel_y)
    begin
        if pixel_x < 320 then
            if pixel_y < 240 then
                -- Top-left quadrant: Red
                red   <= "11";
                green <= "00";
                blue  <= "00";
            else
                -- Bottom-left quadrant: Green
                red   <= "00";
                green <= "11";
                blue  <= "00";
            end if;
        else
            if pixel_y < 240 then
                -- Top-right quadrant: Blue
                red   <= "00";
                green <= "00";
                blue  <= "11";
            else
                -- Bottom-right quadrant: White
                red   <= "11";
                green <= "11";
                blue  <= "11";
            end if;
        end if;
    end process;
end Behavioral;
