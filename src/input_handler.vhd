library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity input_handler is
    Port (
        clk         : in  std_logic;                  -- Clock signal
        reset       : in  std_logic;                  -- Raw reset signal
        raw_left    : in  std_logic;                  -- Raw left button signal
        raw_right   : in  std_logic;                  -- Raw right button signal
        raw_rotate  : in  std_logic;                  -- Raw rotate button signal
        move_left   : out std_logic;                  -- Debounced left button signal
        move_right  : out std_logic;                  -- Debounced right button signal
        rotate      : out std_logic;                  -- Debounced rotate button signal
        debounced_reset : buffer std_logic              -- Debounced reset signal (optional)
        --led         : out std_logic_vector(1 downto 0) -- LEDs for testing
    );
end input_handler;

architecture Behavioral of input_handler is
    component debounce is
        port(
            clk   : in  std_logic;
            btn_r : in  std_logic;  -- Button mapped to reset
            btn_b : in  std_logic;  -- Button mapped to move_left
            btn_y : in  std_logic;  -- Button mapped to rotate
            btn_g : in  std_logic;  -- Button mapped to move_right
            out_r : out std_logic;  -- Debounced reset
            out_b : out std_logic;  -- Debounced move_left
            out_y : out std_logic;  -- Debounced rotate
            out_g : out std_logic   -- Debounced move_right
        );
    end component;

    -- Signals for debounced outputs
    --signal debounced_reset   : std_logic;
    signal debounced_left    : std_logic;
    signal debounced_rotate  : std_logic;
    signal debounced_right   : std_logic;

begin
    -- Map the debounce module to handle all buttons
    debounce_inst: debounce
        port map (
            clk   => clk,
            btn_r => reset,            -- Raw reset signal
            btn_b => raw_left,         -- Raw left button signal
            btn_y => raw_rotate,       -- Raw rotate button signal
            btn_g => raw_right,        -- Raw right button signal
            out_r => debounced_reset,  -- Debounced reset signal
            out_b => debounced_left,   -- Debounced left button signal
            out_y => debounced_rotate, -- Debounced rotate button signal
            out_g => debounced_right   -- Debounced right button signal
        );

    -- Assign debounced signals to outputs
    move_left        <= debounced_left;   -- Debounced left button signal
    move_right       <= debounced_right;  -- Debounced right button signal
    rotate           <= debounced_rotate; -- Debounced rotate button signal
    debounced_reset  <= debounced_reset;  -- Debounced reset signal (optional)

    -- LED Testing Logic
--    process(clk, reset)
--    begin
--        if reset = '1' then
--            led <= "00"; -- Reset LEDs to 0
--        elsif rising_edge(clk) then
--            if debounced_left = '1' then
--                led <= "01"; -- Binary 1 for move_left
--            elsif debounced_right = '1' then
--                led <= "10"; -- Binary 2 for move_right
--            elsif debounced_rotate = '1' then
--                led <= "11"; -- Binary 3 for rotate
--            else
--                led <= "00"; -- Default state
--            end if;
--        end if;
--    end process;

end Behavioral;
