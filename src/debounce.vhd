library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity debounce is
    port(
        clk:   in  std_logic;
        rx:    in  std_logic;
        tx:    out std_logic;
        btn_r: in  std_logic;
        btn_b: in  std_logic;
        btn_y: in  std_logic;
        btn_g: in  std_logic
    );
end debounce;

architecture arch of debounce is

    signal cntr: unsigned(6 downto 0) := (others => '0');
    signal cntb: unsigned(6 downto 0) := (others => '0');
    signal cnty: unsigned(6 downto 0) := (others => '0');
    signal cntg: unsigned(6 downto 0) := (others => '0');

    -- Debounced signals
    signal btn_r_filtered: std_logic := '0';
    signal btn_b_filtered: std_logic := '0';
    signal btn_y_filtered: std_logic := '0';
    signal btn_g_filtered: std_logic := '0';

    -- Saturation counters for debounce
    signal counter_r: unsigned(3 downto 0) := (others => '0');
    signal counter_b: unsigned(3 downto 0) := (others => '0');
    signal counter_y: unsigned(3 downto 0) := (others => '0');
    signal counter_g: unsigned(3 downto 0) := (others => '0');

    -- Edge detection signals
    signal btn_r_last: std_logic := '0';
    signal btn_b_last: std_logic := '0';
    signal btn_y_last: std_logic := '0';
    signal btn_g_last: std_logic := '0';

begin
    -- Process to handle debounce and edge detection
    process(clk)
    begin
        if rising_edge(clk) then
            -- Debounced Red button
            if btn_r = '1' then
                if counter_r /= "1111" then
                    counter_r <= counter_r + 1;
                else
                    btn_r_filtered <= '1';
                end if;
            else
                if counter_r /= "0000" then
                    counter_r <= counter_r - 1;
                else
                    btn_r_filtered <= '0';
                end if;
            end if;

            -- Debounced Blue button
            if btn_b = '1' then
                if counter_b /= "1111" then
                    counter_b <= counter_b + 1;
                else
                    btn_b_filtered <= '1';
                end if;
            else
                if counter_b /= "0000" then
                    counter_b <= counter_b - 1;
                else
                    btn_b_filtered <= '0';
                end if;
            end if;

            -- Debounced Yellow button
            if btn_y = '1' then
                if counter_y /= "1111" then
                    counter_y <= counter_y + 1;
                else
                    btn_y_filtered <= '1';
                end if;
            else
                if counter_y /= "0000" then
                    counter_y <= counter_y - 1;
                else
                    btn_y_filtered <= '0';
                end if;
            end if;

            -- Debounced Green button
            if btn_g = '1' then
                if counter_g /= "1111" then
                    counter_g <= counter_g + 1;
                else
                    btn_g_filtered <= '1';
                end if;
            else
                if counter_g /= "0000" then
                    counter_g <= counter_g - 1;
                else
                    btn_g_filtered <= '0';
                end if;
            end if;

            -- Edge detection for Red button
            if btn_r_filtered = '1' and btn_r_last = '0' then
                cntr <= cntr + 1;
            end if;
            btn_r_last <= btn_r_filtered;

            -- Edge detection for Blue button
            if btn_b_filtered = '1' and btn_b_last = '0' then
                cntb <= cntb + 1;
            end if;
            btn_b_last <= btn_b_filtered;

            -- Edge detection for Yellow button
            if btn_y_filtered = '1' and btn_y_last = '0' then
                cnty <= cnty + 1;
            end if;
            btn_y_last <= btn_y_filtered;

            -- Edge detection for Green button
            if btn_g_filtered = '1' and btn_g_last = '0' then
                cntg <= cntg + 1;
            end if;
            btn_g_last <= btn_g_filtered;
        end if;
    end process;
end arch;
