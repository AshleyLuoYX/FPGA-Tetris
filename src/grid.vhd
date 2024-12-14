library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.tetris_utils.all;

entity grid is Port (
    clk     : in  STD_LOGIC;
    raddr  : in  STD_LOGIC_VECTOR (8 downto 0);
    raddr_clear : in  STD_LOGIC_VECTOR (8 downto 0);
    wen     : in  STD_LOGIC;
    waddr   : in  STD_LOGIC_VECTOR (8 downto 0);
    wpixel  : in  STD_LOGIC;
    rpixel : out STD_LOGIC;
    rpixel_clear : out std_logic
);
end grid;

architecture Behavioral of grid is
    -- signal data : std_logic_vector ((ROWS * COLS) - 1 downto 0);
    signal data : std_logic_vector ((ROWS * COLS) - 1 downto 0);

begin

rpixel <= data(to_integer((unsigned(raddr))));
rpixel_clear <= data(to_integer((unsigned(raddr_clear))));

process (clk) begin
if rising_edge(clk) then
    if wen = '1' then
        data(to_integer((unsigned(waddr)))) <= wpixel;
    end if;
end if;
end process;
end Behavioral;
