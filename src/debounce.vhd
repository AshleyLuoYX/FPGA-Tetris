library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity debounce is
    port(
        clk   : in  std_logic;
        btn_r : in  std_logic; -- Raw Red button
        btn_b : in  std_logic; -- Raw Blue button
        btn_y : in  std_logic; -- Raw Yellow button
        btn_g : in  std_logic; -- Raw Green button
        out_r : out std_logic; -- Debounced Red button
        out_b : out std_logic; -- Debounced Blue button
        out_y : out std_logic; -- Debounced Yellow button
        out_g : out std_logic  -- Debounced Green button
        --led   : out std_logic_vector(1 downto 0) -- LEDs for testing
    );
end debounce;

architecture Behavioral of debounce is
    -- Saturation counters for debounce
    signal counter_r : unsigned(3 downto 0) := (others => '0');
    signal counter_b : unsigned(3 downto 0) := (others => '0');
    signal counter_y : unsigned(3 downto 0) := (others => '0');
    signal counter_g : unsigned(3 downto 0) := (others => '0');

    -- Debounced signals
    signal btn_r_filtered : std_logic := '0';
    signal btn_b_filtered : std_logic := '0';
    signal btn_y_filtered : std_logic := '0';
    signal btn_g_filtered : std_logic := '0';

begin
    -- Debouncing Process
    process(clk)
    begin
        if rising_edge(clk) then
            -- Red Button Debounce Logic
            if btn_r = '1' then
                if counter_r /= "1111" then
                    counter_r <= counter_r + 1;
                end if;
            else
                if counter_r /= "0000" then
                    counter_r <= counter_r - 1;
                end if;
            end if;

            if counter_r = "1111" then
                btn_r_filtered <= '1';
            elsif counter_r = "0000" then
                btn_r_filtered <= '0';
            end if;

            -- Blue Button Debounce Logic
            if btn_b = '1' then
                if counter_b /= "1111" then
                    counter_b <= counter_b + 1;
                end if;
            else
                if counter_b /= "0000" then
                    counter_b <= counter_b - 1;
                end if;
            end if;

            if counter_b = "1111" then
                btn_b_filtered <= '1';
            elsif counter_b = "0000" then
                btn_b_filtered <= '0';
            end if;

            -- Yellow Button Debounce Logic
            if btn_y = '1' then
                if counter_y /= "1111" then
                    counter_y <= counter_y + 1;
                end if;
            else
                if counter_y /= "0000" then
                    counter_y <= counter_y - 1;
                end if;
            end if;

            if counter_y = "1111" then
                btn_y_filtered <= '1';
            elsif counter_y = "0000" then
                btn_y_filtered <= '0';
            end if;

            -- Green Button Debounce Logic
            if btn_g = '1' then
                if counter_g /= "1111" then
                    counter_g <= counter_g + 1;
                end if;
            else
                if counter_g /= "0000" then
                    counter_g <= counter_g - 1;
                end if;
            end if;

            if counter_g = "1111" then
                btn_g_filtered <= '1';
            elsif counter_g = "0000" then
                btn_g_filtered <= '0';
            end if;
        end if;
    end process;

    -- Assign Debounced Signals to Outputs
    out_r <= btn_r_filtered;
    out_b <= btn_b_filtered;
    out_y <= btn_y_filtered;
    out_g <= btn_g_filtered;

     -- LED Testing Process
--    process(clk)
--    begin
--        if rising_edge(clk) then
--            if btn_r_filtered = '1' then
--                led <= "01"; -- LED pattern for Red
--            elsif btn_b_filtered = '1' then
--                led <= "10"; -- LED pattern for Blue
--            elsif btn_y_filtered = '1' then
--                led <= "11"; -- LED pattern for Yellow
--            elsif btn_g_filtered = '1' then
--                led <= "00"; -- LED pattern for Green
--            else
--                led <= "00"; -- Default state
--            end if;
--        end if;
--    end process;
    
end Behavioral;
