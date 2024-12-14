library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- cuts down on type conversions
use work.tetris_utils.ALL;

entity clear is Port (
    clk    : in  STD_LOGIC;
    lock   : in  STD_LOGIC; -- signal raised when a block has done falling
    done   : out STD_LOGIC := '0';
    raddr_grid : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
    raddr_shadow : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
    rpixel_grid : in STD_LOGIC := '0';
    rpixel_shadow : in std_logic := '0';
    wen_grid : out STD_LOGIC := '0';
    wen_shadow : out STD_LOGIC := '0';
    wpixel1 : out STD_LOGIC := '0';
    wpixel2 : out STD_LOGIC := '0';
    waddr_grid : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
    waddr_shadow : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
    row_cleared : out STD_LOGIC := '0'
    -- led : out STD_LOGIC_VECTOR (1 downto 0)
    );
end clear;

architecture Behavioral of clear is
    type clear_state_type is (IDLE, READ, CLEAR);
    signal state_grid : clear_state_type := IDLE;
    signal done_grid : std_logic := '0';
    signal row_grid : integer range 0 to ROWS - 1 := ROWS - 1;
    signal col_grid : integer range 0 to COLS - 1 := 3;
    signal delay_grid : std_logic := '0';
    
    signal state_shadow : clear_state_type := IDLE;
    signal done_shadow : std_logic := '0';
    signal row_shadow : integer range 0 to ROWS - 1 := ROWS - 1;
    signal col_shadow : integer range 0 to COLS - 1 := 3;
    signal delay_shadow : std_logic := '0';
    -- signal row_grid, count_grid, write_grid : STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
    -- signal row_shadow, count_shadow, write_shadow : STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
    -- type statetype is (IDLE, CLEAR);
    -- signal state_grid : statetype := IDLE;
    -- signal state_shadow : statetype := IDLE;
    -- signal done_grid, done_shadow : STD_LOGIC := '0';

begin
    done <= done_grid or done_shadow;

    grid_clear : process (clk) 
    begin
        if rising_edge(clk) then
            case (state_grid) is
                when IDLE =>
                    row_cleared <= '0';
                    wen_grid    <= '0';
                    waddr_grid  <= (others => '0');
                    wpixel1     <= '0';

                    done_grid   <= '0';
                    row_grid    <= ROWS - 1;
                    col_grid    <= 3;
                    if lock = '1' then
                        state_grid <= READ;
                    end if;

                when READ =>
                    if row_grid > 2 then
                        -- if col_grid > 2 and col_grid < COLS - 3 then
                            if delay_grid = '0' then
                                raddr_grid <= std_logic_vector(to_unsigned(row_grid * COLS + col_grid, raddr_grid'length));
                                delay_grid <= '1';
                            else
                                delay_grid <= '0';
                                if rpixel_grid = '0' then
                                    row_grid <= row_grid - 1;
                                    col_grid <= 3;
                                elsif col_grid = COLS - 4 then
                                    state_grid <= CLEAR;
                                    col_grid <= 3;
                                else
                                    col_grid <= col_grid + 1;
                                end if;
                            end if;
                        -- end if;
                    else
                        state_grid <= IDLE;
                        done_grid  <= '1';
                    end if;
                
                when CLEAR =>
                    row_cleared <= '1';
                    if row_grid > 3 then
                        if delay_grid = '0' then
                            raddr_grid <= std_logic_vector(to_unsigned((row_grid - 1) * COLS + col_grid, raddr_grid'length));
                            delay_grid <= '1';
                        else
                            delay_grid <= '0';
                            waddr_grid <= std_logic_vector(to_unsigned(row_grid * COLS + col_grid, waddr_grid'length));
                            wen_grid   <= '1';
                            wpixel1    <= rpixel_grid;
                            -- wpixel1    <= '0';
                            if col_grid = COLS - 3 then
                                row_grid <= row_grid - 1;
                                col_grid <= 3;
                                wen_grid <= '0';
                            else
                                col_grid <= col_grid + 1;
                            end if;
                        end if;
                    end if;

                    if row_grid = 3 then
                        waddr_grid <= std_logic_vector(to_unsigned(row_grid * COLS + col_grid, waddr_grid'length));
                        wen_grid   <= '1';
                        wpixel1    <= '0';
                        if col_grid = COLS - 3 then
                            state_grid <= READ;
                            wen_grid   <= '0';
                            row_grid   <= ROWS - 1;
                            col_grid   <= 3;
                        else
                            col_grid <= col_grid + 1;
                        end if;
                    end if;

                when others =>
            end case;
        end if;
    end process;

    shadow_clear : process (clk) 
    begin
        if rising_edge(clk) then
            case (state_shadow) is
                when IDLE =>
                    wen_shadow    <= '0';
                    waddr_shadow  <= (others => '0');
                    wpixel2       <= '0';

                    done_shadow   <= '0';
                    row_shadow    <= ROWS - 1;
                    col_shadow    <= 3;
                    if lock = '1' then
                        state_shadow <= READ;
                    end if;

                when READ =>
                    if row_shadow > 2 then
                        -- if col_shadow > 2 and col_shadow < COLS - 3 then
                            if delay_shadow = '0' then
                                raddr_shadow <= std_logic_vector(to_unsigned(row_shadow * COLS + col_shadow, raddr_shadow'length));
                                delay_shadow <= '1';
                            else
                                delay_shadow <= '0';
                                if rpixel_shadow = '0' then
                                    row_shadow <= row_shadow - 1;
                                    col_shadow <= 3;
                                elsif col_shadow = COLS - 4 then
                                    state_shadow <= CLEAR;
                                    col_shadow <= 3;
                                else
                                    col_shadow <= col_shadow + 1;
                                end if;
                            end if;
                        -- end if;
                    else
                        state_shadow <= IDLE;
                        done_shadow  <= '1';
                    end if;
                
                when CLEAR =>
                    if row_shadow > 3 then
                        if delay_shadow = '0' then
                            raddr_shadow <= std_logic_vector(to_unsigned((row_shadow - 1) * COLS + col_shadow, raddr_shadow'length));
                            delay_shadow <= '1';
                        else
                            delay_shadow <= '0';
                            waddr_shadow <= std_logic_vector(to_unsigned(row_shadow * COLS + col_shadow, waddr_shadow'length));
                            wen_shadow   <= '1';
                            wpixel2    <= rpixel_shadow;
                            -- wpixel2    <= '0';
                            if col_shadow = COLS - 3 then
                                row_shadow <= row_shadow - 1;
                                col_shadow <= 3;
                                wen_shadow <= '0';
                            else
                                col_shadow <= col_shadow + 1;
                            end if;
                        end if;
                    end if;

                    if row_shadow = 3 then
                        waddr_shadow <= std_logic_vector(to_unsigned(row_shadow * COLS + col_shadow, waddr_shadow'length));
                        wen_shadow   <= '1';
                        wpixel2    <= '0';
                        if col_shadow = COLS - 3 then
                            state_shadow <= READ;
                            wen_shadow   <= '0';
                            row_shadow   <= ROWS - 1;
                            col_shadow   <= 3;
                        else
                            col_shadow <= col_shadow + 1;
                        end if;
                    end if;

                when others =>
            end case;
        end if;
    end process;

end Behavioral;

