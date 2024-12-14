library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;
    use work.tetris_utils.all;

entity top_level is
    port (
        clk : in std_logic;
        rpixel_grid : in  STD_LOGIC;
        rpixel_shadow : in  STD_LOGIC;
        raddr_grid : out STD_LOGIC_VECTOR (8 downto 0);
        raddr_shadow : out STD_LOGIC_VECTOR (8 downto 0);
        wen_grid : out STD_LOGIC;
        wen_shadow : out STD_LOGIC;
        wpixel_grid : out STD_LOGIC;
        wpixel_shadow : out STD_LOGIC;
        waddr_grid : out STD_LOGIC_VECTOR (8 downto 0);
        waddr_shadow : out STD_LOGIC_VECTOR (8 downto 0);
        drop : in std_logic;
        left : in std_logic;
        right : in std_logic;
        rotate : in std_logic;
        restart_game : in std_logic;
        -- serialized_grid : out std_logic_vector((ROWS * COLS) - 1 downto 0);
        serialized_grid : out std_logic_vector((ROWS * COLS) - 1 downto 0);
        serialized_shadow : out std_logic_vector((ROWS * COLS) - 1 downto 0);
        -- led : out std_logic_vector(1 downto 0) := "00";
        lock : out std_logic;
        done : in std_logic;
        game_over_sig : out std_logic := '0';
        row_cleared : in std_logic
    );
end top_level;

architecture Behavioral of top_level is
    -- State definitions
    type state_type is (LEFTS, RIGHTS, ROTATES, DROPS, GAME_OVER, IDLE, SPAWN, FALL); -- Mealy Machine
    signal state : state_type := GAME_OVER;

    signal collision : std_logic := '0';

    signal piece_pos_x : integer range 0 to COLS - 1 := COLS / 2 - 1;
    signal piece_pos_y : integer range 0 to ROWS - 1 := 0;
    signal score : integer := 0;
    signal block_type : integer range 0 to 6 := 0;
    signal rotation : integer range 0 to 3 := 0;
    signal random_tetromino : integer range 0 to 6 := 0;

    signal count : integer := 0;
    signal serialize_count : integer range 0 to ROWS * COLS := 0;
    signal tetromino : std_logic_vector(0 to 15) := (others => '0');
    signal update_shadow : std_logic := '0';
    signal check_clear_rows : std_logic := '0';
    signal fall_counter : integer range 0 to 11_999_999 := 0;
    signal variable_clk : integer := 11_999_999;
    signal start_visualizing : std_logic := '0';
    signal restart_counter : integer := 0;

begin

    rand_num_inst: entity work.random_num
    port map (
        clk => clk,
        reset => '0',
        random_number => random_tetromino
    );

    -- FSM Output Logic
    fsm_logic: process (clk)
        variable temp_rotation : integer range 0 to 3 := 0;
    begin
        if rising_edge(clk) then
            fall_counter <= fall_counter + 1;
            case state is
                when GAME_OVER =>
                    variable_clk <= 11_999_999;
                    score <= 0;
                    game_over_sig <= '1';
                    -- reset read / write
                    raddr_shadow <= (others => '0');
                    wen_grid <= '0';
                    wen_shadow <= '0';
                    wpixel_grid <= '0';
                    wpixel_shadow <= '0';
                    waddr_grid <= (others => '0');
                    waddr_shadow <= (others => '0');
                    collision <= '0';
                    if restart_game = '1' then
                        if restart_counter < ROWS * COLS then
                            restart_counter <= restart_counter + 1;
                            waddr_shadow <= std_logic_vector(to_unsigned(restart_counter, raddr_shadow'length));
                            waddr_grid <= std_logic_vector(to_unsigned(restart_counter, raddr_grid'length));
                            wen_grid <= '1';
                            wen_shadow <= '1';
                            wpixel_grid <= '0';
                            wpixel_shadow <= '0';
                        else
                            game_over_sig <= '0';
                            state <= SPAWN;
                            count <= 0;
                            restart_counter <= 0;
                            wen_grid <= '0';
                            wen_shadow <= '0';
                            wpixel_grid <= '0';
                            wpixel_shadow <= '0';
                            waddr_grid <= (others => '0');
                            waddr_shadow <= (others => '0');
                        end if;
                    end if;

                when SPAWN =>
                    -- led <= "11";
                    piece_pos_x <= COLS / 2 - 1;
                    piece_pos_y <= 0;
                    rotation <= 0;
                    collision <= '0';

                    if count = 0 then
                        block_type <= random_tetromino;
                        -- block_type <= 6;
                        count <= 1;
                    elsif count > 0 and count < 18 then
                        if count < 17 then
                            tetromino <= fetch_tetromino(block_type, rotation);
                            -- check 4*4 spawn area one by one for collision
                            if tetromino(count-1) = '1' then
                                raddr_shadow <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count-1) / 4) * COLS + ((count-1) mod 4), raddr_shadow'length));
                            end if;
                        end if;
                        if count > 1 then
                            if tetromino(count-2) = '1' then
                                if rpixel_shadow = '1' then
                                    collision <= '1';
                                    state <= GAME_OVER;
                                end if;
                            end if;
                        end if;
                        count <= count + 1;
                    elsif (collision = '0') and (count < 34) then
                        -- write new tetromino to 4*4 area one pixel at a time
                        if tetromino(count - 18) = '1' then
                            waddr_grid <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count-18) / 4) * COLS + ((count-2) mod 4), waddr_grid'length));
                            wen_grid <= '1';
                            wpixel_grid <= '1';
                        end if;
                        count <= count + 1;

                    else
                        wen_grid <= '0';
                        count <= 0;
                        state <= IDLE;
                    end if;

                when IDLE =>
                    -- led <= "00";
                    collision <= '0';
                    if drop = '1' then
                        count <= 0;
                        state <= DROPS;
                    elsif left = '1' then
                        count <= 0;
                        state <= LEFTS;
                    elsif right = '1' then
                        count <= 0;
                        state <= RIGHTS;
                    elsif rotate = '1' then
                        count <= 0;
                        state <= ROTATES;
                    else
                        count <= 0;
                        state <= FALL;
                        -- end if;
                    end if;

                when LEFTS =>
                    if count < 16 then
                        -- delete tetromino in 4*4 area one pixel at a time
                        if tetromino(count) = '1' then
                            waddr_grid <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + count / 4) * COLS + (count mod 4), waddr_grid'length));
                            wen_grid <= '1';
                            wpixel_grid <= '0';
                        end if;
                        count <= count + 1;

                    elsif count < 33 then
                        count <= count + 1;
                        if count < 32 then
                            wen_grid <= '0';
                            tetromino <= fetch_tetromino(block_type, rotation);
                            -- check 4*4 area one by one for collision
                            if tetromino(count - 16) = '1' then
                                if ((piece_pos_x - 1 + ((count) mod 4) < 3) or (piece_pos_x - 1 + ((count) mod 4) > COLS - 4)) then
                                    collision <= '1';
                                    count <= 0;
                                    state <= FALL;
                                else
                                    raddr_shadow <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count-16) / 4) * COLS + (count mod 4) - 1, raddr_shadow'length));
                                end if;
                            end if;
                        end if;
                        if count > 16 then
                            if tetromino(count - 17) = '1' then
                                if rpixel_shadow = '1' or ((piece_pos_x - 1 + ((count-1) mod 4) < 3) or (piece_pos_x - 1 + ((count-1) mod 4) > COLS - 4)) then
                                    collision <= '1';
                                    count <= 0;
                                    state <= FALL;
                                end if;
                            end if;
                        end if;
                    else
                        if collision = '0' then
                            piece_pos_x <= piece_pos_x - 1;
                        end if;
                        count <= 0;
                        state <= FALL;
                    end if;

                when RIGHTS =>
                    if count < 16 then
                        -- delete tetromino in 4*4 area one pixel at a time
                        if tetromino(count) = '1' then
                            waddr_grid <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + count / 4) * COLS + (count mod 4), waddr_grid'length));
                            wen_grid <= '1';
                            wpixel_grid <= '0';
                        end if;
                        count <= count + 1;

                    elsif count < 33 then
                        count <= count + 1;
                        if count < 32 then
                            wen_grid <= '0';
                            tetromino <= fetch_tetromino(block_type, rotation);
                            -- check 4*4 area one by one for collision
                            if tetromino(count - 16) = '1' then
                                if ((piece_pos_x + 1 + ((count) mod 4) < 3) or (piece_pos_x + 1 + ((count) mod 4) > COLS - 4)) then
                                    collision <= '1';
                                    count <= 0;
                                    state <= FALL;
                                else
                                    raddr_shadow <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count-16) / 4) * COLS + (count mod 4) + 1, raddr_shadow'length));
                                end if;
                            end if;
                        end if;
                        if count > 16 then
                            if tetromino(count - 17) = '1' then
                                if rpixel_shadow = '1' or ((piece_pos_x + 1 + ((count-1) mod 4) < 3) or (piece_pos_x + 1 + ((count-1) mod 4) > COLS - 4)) then
                                    collision <= '1';
                                    count <= 0;
                                    state <= FALL;
                                end if;
                            end if;
                        end if;
                    else
                        if collision = '0' then
                            piece_pos_x <= piece_pos_x + 1;
                        end if;
                        count <= 0;
                        state <= FALL;
                    end if;

                when ROTATES =>
                    if count < 16 then
                        -- delete tetromino in 4*4 area one pixel at a time
                        if tetromino(count) = '1' then
                            waddr_grid <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + count / 4) * COLS + (count mod 4), waddr_grid'length));
                            wen_grid <= '1';
                            wpixel_grid <= '0';
                        end if;
                        count <= count + 1;

                    elsif count = 16 then
                        wen_grid <= '0';
                        temp_rotation := (rotation + 1) mod 4;
                        tetromino <= fetch_tetromino(block_type, temp_rotation);
                        count <= count + 1;

                    elsif count < 34 then
                        count <= count + 1;
                        if count < 33 then
                            -- check 4*4 area one by one for collision
                            if tetromino(count - 17) = '1' then
                                raddr_shadow <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count-17) / 4) * COLS + ((count-1) mod 4), raddr_shadow'length));
                            end if;
                        end if;
                        if count > 17 then
                            if tetromino(count - 18) = '1' then
                                if rpixel_shadow = '1' or ((piece_pos_x + ((count-2) mod 4) < 3) or (piece_pos_x + ((count-2) mod 4) > COLS - 4)) or (piece_pos_y + (count-18) / 4 > ROWS - 1) then
                                    collision <= '1';
                                    count <= 0;
                                    state <= FALL;
                                end if;
                            end if;
                        end if;
                    else
                        if collision = '0' then
                            rotation <= temp_rotation;
                        end if;
                        count <= 0;
                        state <= FALL;
                    end if;

                when FALL =>
                    -- led <= "10";
                    if count < 17 then
                        if count < 16 then
                            tetromino <= fetch_tetromino(block_type, rotation);
                            -- check 4*4 area one by one for collision
                            if tetromino(count) = '1' then
                                raddr_shadow <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + count / 4 + 1) * COLS + (count mod 4), raddr_shadow'length)); -- bottom
                            end if;
                        end if;
                        if count > 0 then
                            if tetromino(count - 1) = '1' then
                                if rpixel_shadow = '1' or (piece_pos_y + (count-1) / 4 + 1 > ROWS - 1) then
                                    collision <= '1';
                                    update_shadow <= '1';
                                    check_clear_rows <= '1';
                                end if;
                            end if;
                        end if;
                            count <= count + 1;
                            -- wpixel_grid <= '0';

                    elsif count > 16 and count < 33 then
                        -- delete tetromino in 4*4 area one pixel at a time
                        if tetromino(count - 17) = '1' then
                            waddr_grid <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count - 17) / 4) * COLS + ((count-1) mod 4), waddr_grid'length));
                            wen_grid <= '1';
                            wpixel_grid <= '0';
                        end if;
                        count <= count + 1;

                    elsif count > 32 and count < 49 then
                        -- write new tetromino to 4*4 area one pixel at a time
                        if tetromino(count - 33) = '1' then
                            if update_shadow = '0' then
                                waddr_grid <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count - 33) / 4 + 1) * COLS + ((count-1) mod 4), waddr_grid'length));
                                wen_grid <= '1';
                                wpixel_grid <= '1';
                            else
                                waddr_grid <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count - 33) / 4) * COLS + ((count-1) mod 4), waddr_grid'length));
                                wen_grid <= '1';
                                wpixel_grid <= '1';
                                waddr_shadow <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count - 33) / 4) * COLS + ((count-1) mod 4), waddr_shadow'length));
                                wen_shadow <= '1';
                                wpixel_shadow <= '1';
                            end if;
                        end if;
                        count <= count + 1;

                    elsif count > 48 and fall_counter < variable_clk and start_visualizing = '0' then
                        -- do nothing
                        wen_grid <= '0';
                        wen_shadow <= '0';

                        wpixel_grid <= '0';
                        wpixel_shadow <= '0';

                        waddr_grid <= (others => '0');
                        waddr_shadow <= (others => '0');

                        if check_clear_rows = '1' then
                            lock <= '1';
                        else
                            start_visualizing <= '1';
                        end if;

                        if done = '1' then
                            --led <= "11";
                            if row_cleared = '1' then
                                score <= score + 1;
                            end if;
                            if variable_clk > 1_000_000 then
                                variable_clk <= 11_999_999 - score*1_500_000;
                            else
                                variable_clk <= 500_000;
                            end if;
                            lock <= '0';
                            start_visualizing <= '1';
                            check_clear_rows <= '0';
                        end if;

                    elsif count > 48 and fall_counter < variable_clk and start_visualizing = '1' then

                        -- serialize shadow grid
                        if serialize_count < ROWS * COLS + 1 then
                            serialize_count <= serialize_count + 1;
                            if serialize_count < ROWS * COLS then
                                raddr_shadow <= std_logic_vector(to_unsigned(serialize_count, raddr_shadow'length));
                            end if;
                            if serialize_count > 0 then
                                serialized_shadow(serialize_count - 1) <= rpixel_shadow;
                            end if;
                        else
                            serialize_count <= 0;
                        end if;

                        -- serialize grid
                        if serialize_count < ROWS * COLS + 1 then
                            serialize_count <= serialize_count + 1;
                            if serialize_count < ROWS * COLS then
                                raddr_grid <= std_logic_vector(to_unsigned(serialize_count, raddr_grid'length));
                            end if;
                            if serialize_count > 0 then
                                serialized_grid(serialize_count - 1) <= rpixel_grid;
                            end if;
                        else
                            serialize_count <= 0;
                        end if;

                    else
                        start_visualizing <= '0';
                        check_clear_rows <= '0';
                        if update_shadow = '1' then
                            state <= SPAWN;
                            count <= 0;
                            update_shadow <= '0';
                            collision <= '0';
                        else
                            piece_pos_y <= piece_pos_y + 1;
                            count <= 0;
                            state <= IDLE;
                        end if;
                        fall_counter <= 0;
                    end if;

                when DROPS =>
                    if count < 17 then
                        start_visualizing <= '0';
                        if count < 16 then
                            tetromino <= fetch_tetromino(block_type, rotation);
                            -- check 4*4 area one by one for collision
                            if tetromino(count) = '1' then
                                raddr_shadow <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + count / 4 + 1) * COLS + (count mod 4), raddr_shadow'length)); -- bottom
                            end if;
                        end if;
                        if count > 0 then
                            if tetromino(count - 1) = '1' then
                                if rpixel_shadow = '1' or (piece_pos_y + (count-1) / 4 + 1 > ROWS - 1) then
                                    collision <= '1';
                                    check_clear_rows <= '1';
                                end if;
                            end if;
                        end if;
                            count <= count + 1;
                            -- wpixel_grid <= '0';

                    elsif count > 16 and count < 33 then
                        -- delete tetromino in 4*4 area one pixel at a time
                        if tetromino(count - 17) = '1' then
                            waddr_grid <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count - 17) / 4) * COLS + ((count-1) mod 4), waddr_grid'length));
                            wen_grid <= '1';
                            wpixel_grid <= '0';
                        end if;
                        count <= count + 1;

                    elsif count > 32 and count < 49 then
                        -- write new tetromino to 4*4 area one pixel at a time
                        if tetromino(count - 33) = '1' then
                            if collision = '0' then
                                waddr_grid <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count - 33) / 4 + 1) * COLS + ((count-1) mod 4), waddr_grid'length));
                                wen_grid <= '1';
                                wpixel_grid <= '1';
                            else
                                waddr_grid <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count - 33) / 4) * COLS + ((count-1) mod 4), waddr_grid'length));
                                wen_grid <= '1';
                                wpixel_grid <= '1';
                                waddr_shadow <= std_logic_vector(to_unsigned(piece_pos_x + (piece_pos_y + (count - 33) / 4) * COLS + ((count-1) mod 4), waddr_shadow'length));
                                wen_shadow <= '1';
                                wpixel_shadow <= '1';
                            end if;
                        end if;

                        if collision = '1' then
                            count <= count + 1;
                        else
                            count <= 0;
                            piece_pos_y <= piece_pos_y + 1;
                        end if;

                    -- elsif count > 48 and fall_counter < 11_999_999 and collision = '1' then
                    --     -- do nothing
                    --     wen_grid <= '0';
                    --     wen_shadow <= '0';

                    elsif count > 48 and fall_counter < variable_clk and start_visualizing = '0' then
                        -- do nothing
                        wen_grid <= '0';
                        wen_shadow <= '0';

                        wpixel_grid <= '0';
                        wpixel_shadow <= '0';

                        waddr_grid <= (others => '0');
                        waddr_shadow <= (others => '0');

                        if check_clear_rows = '1' then
                            lock <= '1';
                        else
                            start_visualizing <= '1';
                        end if;

                        if done = '1' then
                            --led <= "11";
                            if row_cleared = '1' then
                                score <= score + 1;
                            end if;
                            if variable_clk > 1_000_000 then
                                variable_clk <= 11_999_999 - score*1_500_000;
                            else
                                variable_clk <= 500_000;
                            end if;
                            lock <= '0';
                            start_visualizing <= '1';
                            check_clear_rows <= '0';
                        end if;

                    elsif count > 48 and fall_counter < variable_clk and start_visualizing = '1' then

                        -- serialize shadow grid
                        if serialize_count < ROWS * COLS + 1 then
                            serialize_count <= serialize_count + 1;
                            if serialize_count < ROWS * COLS then
                                raddr_shadow <= std_logic_vector(to_unsigned(serialize_count, raddr_shadow'length));
                            end if;
                            if serialize_count > 0 then
                                serialized_shadow(serialize_count - 1) <= rpixel_shadow;
                            end if;
                        else
                            serialize_count <= 0;
                        end if;

                        -- serialize grid
                        if serialize_count < ROWS * COLS + 1 then
                            serialize_count <= serialize_count + 1;
                            if serialize_count < ROWS * COLS then
                                raddr_grid <= std_logic_vector(to_unsigned(serialize_count, raddr_grid'length));
                            end if;
                            if serialize_count > 0 then
                                serialized_grid(serialize_count - 1) <= rpixel_grid;
                            end if;
                        else
                            serialize_count <= 0;
                        end if;

                    else
                        start_visualizing <= '0';
                        state <= SPAWN;
                        count <= 0;
                        collision <= '0';
                        fall_counter <= 0;
                    end if;


                when others =>
                    -- state <= GAME_OVER;

            end case;
        end if;
    end process;

end Behavioral;
