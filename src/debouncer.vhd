library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debouncer is
    Port (
        clk       : in  std_logic;        -- Clock signal
        reset     : in  std_logic;        -- Reset signal
        button_in : in  std_logic;        -- Raw button input
        button_out: out std_logic         -- Debounced button output
    );
end debouncer;

architecture Behavioral of debouncer is
    constant DEBOUNCE_TIME : integer := 50000; -- Adjust for your clock frequency
    signal counter         : integer range 0 to DEBOUNCE_TIME := 0;
    signal stable_state    : std_logic := '0';
begin
    process (clk, reset)
    begin
        if reset = '1' then
            counter <= 0;
            stable_state <= '0';
            button_out <= '0';
        elsif rising_edge(clk) then
            if button_in /= stable_state then
                counter <= counter + 1;
                if counter = DEBOUNCE_TIME then
                    stable_state <= button_in;
                    button_out <= button_in;
                    counter <= 0;
                end if;
            else
                counter <= 0;
            end if;
        end if;
    end process;
end Behavioral;
