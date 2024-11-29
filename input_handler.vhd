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
    component debouncer is
        Port (
            clk       : in  std_logic;
            reset     : in  std_logic;
            button_in : in  std_logic;
            button_out: out std_logic
        );
    end component;

begin
    debounce_left: debouncer
        port map (
            clk => clk,
            reset => reset,
            button_in => raw_left,
            button_out => move_left
        );

    debounce_right: debouncer
        port map (
            clk => clk,
            reset => reset,
            button_in => raw_right,
            button_out => move_right
        );

    debounce_rotate: debouncer
        port map (
            clk => clk,
            reset => reset,
            button_in => raw_rotate,
            button_out => rotate
        );
end Behavioral;
