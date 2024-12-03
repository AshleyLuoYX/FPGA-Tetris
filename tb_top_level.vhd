library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.tetris_utils.all;

entity tb_top_level is
    -- Testbench does not have any ports
end entity;

architecture Behavioral of tb_top_level is

    -- Component declaration for the top-level entity
    component top_level
        port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            red        : out std_logic_vector(1 downto 0);
            green      : out std_logic_vector(1 downto 0);
            blue       : out std_logic_vector(1 downto 0);
            hsync      : out std_logic;
            vsync      : out std_logic;
            grid_debug : out std_logic_vector((20 * 12) - 1 downto 0) -- Debug grid output
        );
    end component;

    -- Signals to connect to the top-level entity
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0';
    signal red        : std_logic_vector(1 downto 0);
    signal green      : std_logic_vector(1 downto 0);
    signal blue       : std_logic_vector(1 downto 0);
    signal hsync      : std_logic;
    signal vsync      : std_logic;
    signal grid_debug : std_logic_vector((20 * 12) - 1 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns; -- 12 MHz clock period

    -- Function to deserialize the grid for debugging
    function deserialize_grid(serialized : std_logic_vector) return Grid is
        variable grid : Grid;
    begin
        for row in 0 to 19 loop
            for col in 0 to 11 loop
                grid(row, col) := serialized((row * 12) + col);
            end loop;
        end loop;
        return grid;
    end function;

begin

    -- Instantiate the top-level entity
    uut: top_level
        port map (
            clk        => clk,
            reset      => reset,
            red        => red,
            green      => green,
            blue       => blue,
            hsync      => hsync,
            vsync      => vsync,
            grid_debug => grid_debug -- Connect the debug grid
        );

    -- Clock generation process
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Infinite Test Process
    test_process: process
        variable grid_array : Grid;
        variable grid_string : string(1 to 20 * (12 + 1)); -- Extra space for newline characters
        variable row_string : string(1 to 12);
        variable index : integer := 1; -- To track grid_string indexing
    begin
--        -- Apply reset
--        reset <= '1';
--        wait for clk_period * 2;
--        reset <= '0';
--        wait for clk_period * 2;

        -- Infinite loop to print the grid on every clock cycle
        while true loop
            wait for 2*clk_period*100; -- Wait for one clock cycle
            grid_array := deserialize_grid(grid_debug);

            -- Initialize the grid_string
            index := 1;
            for row in 0 to 19 loop
                -- Convert each row to a string
                for col in 0 to 11 loop
                    if grid_array(row, col) = '1' then
                        grid_string(index) := 'X';
                    else
                        grid_string(index) := '.';
                    end if;
                    index := index + 1;
                end loop;
                -- Add a newline character after each row
                grid_string(index) := LF; -- Line Feed character
                index := index + 1;
            end loop;

            -- Print the entire grid as a single report statement
            report grid_string;
        end loop;

    end process;

end Behavioral;
