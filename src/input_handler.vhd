library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity input_handler is
    Port (
        clk         : in  std_logic; -- Clock signal
        reset       : in  std_logic; -- Reset signal
        raw_left    : in  std_logic; -- Raw left button signal
        raw_right   : in  std_logic; -- Raw right button signal
        raw_rotate  : in  std_logic; -- Raw rotate button signal
        move_left   : out std_logic; -- Debounced left button signal
        move_right  : out std_logic; -- Debounced right button signal
        rotate      : out std_logic  -- Debounced rotate button signal
    );
end input_handler;

architecture Behavioral of input_handler is
    component debounce is
        port(
            clk:   in  std_logic;
            btn_r: in  std_logic;  -- Button mapped to reset
            btn_b: in  std_logic;  -- Button mapped to move_left
            btn_y: in  std_logic;  -- Button mapped to rotate
            btn_g: in  std_logic   -- Button mapped to move_right
        );
    end component;

    -- Signals for debounced outputs
    signal debounced_reset   : std_logic;
    signal debounced_left    : std_logic;
    signal debounced_rotate  : std_logic;
    signal debounced_right   : std_logic;

begin
    -- Map the debounce module to handle all buttons
    debounce_inst: debounce
        port map (
            clk   => clk,
            btn_r => reset,          -- Map btn_r to reset
            btn_b => raw_left,       -- Map btn_b to raw_left
            btn_y => raw_rotate,     -- Map btn_y to raw_rotate
            btn_g => raw_right       -- Map btn_g to raw_right
        );

    -- Assign debounced signals to outputs
    move_left  <= debounced_left;   -- Debounced left button signal
    move_right <= debounced_right;  -- Debounced right button signal
    rotate     <= debounced_rotate; -- Debounced rotate button signal
end Behavioral;
