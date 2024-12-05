library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_divider is
    Port (
        clk_in      : in  std_logic;  -- Input clock (12 MHz)
        reset       : in  std_logic;  -- Reset signal
        divide_count: in integer;     -- Variable divide count
        clk_out     : out std_logic   -- Output clock (1 Hz)
    );
end clock_divider;

architecture Behavioral of clock_divider is

     -- Signal for counter
    signal counter : integer range 0 to 2**31-1 := 0; -- Large enough range for divide counts
    -- Signal for output clock
    signal clk_reg : std_logic := '0';
    
    -- Constant: Number of input clock cycles needed for 1 second
    -- Formula: cycles = input_frequency / output_frequency

begin

    process (clk_in, reset)
    begin
        if reset = '1' then
            -- Reset the counter and output clock
            counter <= 0;
            clk_reg <= '0';
        elsif rising_edge(clk_in) then
            if counter = divide_count-1 then
                -- Toggle the clock and reset the counter
                clk_reg <= not clk_reg;
                counter <= 0;
            else
                -- Increment the counter
                counter <= counter + 1;
            end if;
        end if;
    end process;

    -- Assign the internal clock signal to the output
    clk_out <= clk_reg;

end Behavioral;
