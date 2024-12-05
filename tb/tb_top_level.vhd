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
            grid_debug : out std_logic_vector((20 * 12) - 1 downto 0); -- Debug grid output
            raw_left   : in  std_logic;
            raw_right  : in  std_logic;
            raw_rotate : in  std_logic;
            led        : out std_logic_vector(1 downto 0);
            input_debug : out std_logic
        );
    end component;

    -- Signals to connect to the top-level entity
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0';
    signal raw_left   : std_logic := '0';
    signal raw_right  : std_logic := '0';
    signal raw_rotate : std_logic := '0';
    signal red        : std_logic_vector(1 downto 0);
    signal green      : std_logic_vector(1 downto 0);
    signal blue       : std_logic_vector(1 downto 0);
    signal hsync      : std_logic;
    signal vsync      : std_logic;
    signal grid_debug : std_logic_vector((20 * 12) - 1 downto 0);
    signal led        : std_logic_vector(1 downto 0);
    signal input_debug : std_logic;

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

    -- Procedure to print the grid state
    procedure print_grid(serialized : std_logic_vector) is
        variable grid_array : Grid;
        variable grid_string : string(1 to 20 * (12 + 1)); -- Extra space for newline characters
        variable index : integer := 1; -- To track grid_string indexing
    begin
        -- Deserialize the grid
        grid_array := deserialize_grid(serialized);

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
    end procedure;

    function to_string(signal s : std_logic) return string is
    begin
        if s = '1' then
            return "1";
        else
            return "0";
        end if;
    end function;

begin

    -- Instantiate the top-level entity
    uut: top_level
        port map (
            clk        => clk,
            reset      => reset,
            raw_left   => raw_left,
            raw_right  => raw_right,
            raw_rotate => raw_rotate,
            red        => red,
            green      => green,
            blue       => blue,
            hsync      => hsync,
            vsync      => vsync,
            grid_debug => grid_debug,
            led        => led
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
    begin

        wait for clk_period * 2 * 100;
        print_grid(grid_debug);

        -- Simulate raw_left input
        raw_left <= '1';
        wait for clk_period * 5; -- Let the block move left
        raw_left <= '0';
        wait for clk_period * 100;
        report "Grid state after raw_left input:";
        print_grid(grid_debug);
        wait for clk_period * 100;

        -- Simulate raw_right input
        raw_right <= '1';
        wait for clk_period * 5; -- Let the block move right
        raw_right <= '0';
        wait for clk_period * 100;
        report "Grid state after raw_right input:";
        print_grid(grid_debug);
        wait for clk_period * 100;

        -- Simulate raw_rotate input
        raw_rotate <= '1';
        wait for clk_period * 5; -- Let the block rotate
        raw_rotate <= '0';
        wait for clk_period * 100;
        report "Grid state after raw_rotate input:";
        print_grid(grid_debug);
        wait for clk_period * 100;

        wait for clk_period * 2 * 100;
        print_grid(grid_debug);

        -- End the simulation
        report "Testbench completed.";
        wait;
    end process;

end Behavioral;
