library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity random_num is
    port (
        clk     : in  std_logic;   -- Clock signal
        reset   : in  std_logic;   -- Reset signal
        random_number : out integer range 0 to 6 -- Random number (integer type restricted to 0-6)
    );
end random_num;

architecture Behavioral of random_num is
    signal lfsr : std_logic_vector(7 downto 0) := "10101010"; -- 8-bit LFSR with a seed value
    signal feedback : std_logic;
    signal temp_random : std_logic_vector(2 downto 0);
begin
    -- Combinational feedback logic
    feedback <= lfsr(7) xor lfsr(5) xor lfsr(4) xor lfsr(3); -- Tap positions for maximal length

    -- Clocked process
    process(clk, reset)
    begin
        if reset = '1' then
            lfsr <= "10101010"; -- Reset to the initial seed value
        elsif rising_edge(clk) then
            lfsr <= feedback & lfsr(7 downto 1); -- Shift and insert feedback
        end if;
    end process;

    -- Restrict output to 0-6
    process(clk)
    begin
        if rising_edge(clk) then
            temp_random <= lfsr(2 downto 0); -- Extract lower 3 bits
            if temp_random = "111" then -- Check if the value is 7
                random_number <= 0; -- Default to 0 (or regenerate)
            else
                random_number <= to_integer(unsigned(temp_random)); -- Convert to integer and assign
            end if;
        end if;
    end process;

end Behavioral;
