library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity score_title_generator is
    port (
        clk       : in std_logic;                  -- System clock
        hcount    : in unsigned(9 downto 0);       -- Horizontal pixel counter
        vcount    : in unsigned(9 downto 0);       -- Vertical pixel counter
        obj_red   : out std_logic_vector(1 downto 0); -- Red color signal
        obj_green : out std_logic_vector(1 downto 0); -- Green color signal
        obj_blue  : out std_logic_vector(1 downto 0)  -- Blue color signal
    );
end score_title_generator;

architecture Behavioral of score_title_generator is
    -- "SCORE:" display area (below the Tetris title)
    constant score_start_x : integer := 350;  -- Starting X coordinate for "SCORE:"
    constant score_start_y : integer := 130;   -- Starting Y coordinate for "SCORE:"
    constant block_size : integer := 8;       -- Enlargement factor (8x8 pixels per block)

    -- Updated binary representation of "SCORE:"
    type score_array is array (0 to 10, 0 to 18) of std_logic;
    constant score_bitmap : score_array := (
        "0111001100100101111",
        "1000010010111101000",
        "1011011110111101110",
        "1001010010100101000",
        "0111010010100101111",
        "0000000000000000000",
        "0110010010111101110",
		"1001010010100001001",
		"1001010010111001110",
		"1001001100100001010",
		"0110001100111101001"
    );

    signal score_x, score_y : integer; -- Current pixel position relative to "SCORE:"
    signal block_x, block_y : integer; -- Block coordinates within the enlarged bitmap
    signal cell_x, cell_y : integer;   -- Position within a single 8x8 block
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Calculate pixel position relative to the "SCORE:"'s starting position
            score_x <= to_integer(hcount) - score_start_x;
            score_y <= to_integer(vcount) - score_start_y;

            -- Calculate block coordinates (5x24 grid)
            block_x <= score_x / block_size; -- Horizontal block index
            block_y <= score_y / block_size; -- Vertical block index

            -- Calculate position within the current block (8x8 pixels)
            cell_x <= score_x mod block_size;
            cell_y <= score_y mod block_size;

            -- Check if within "SCORE:" display area
            if (hcount >= to_unsigned(score_start_x, 10)) and
               (hcount < to_unsigned(score_start_x + (19 * block_size), 10)) and -- 24 columns * 8 pixels per block
               (vcount >= to_unsigned(score_start_y, 10)) and
               (vcount < to_unsigned(score_start_y + (11 * block_size), 10)) then -- 5 rows * 8 pixels per block

                -- Render "SCORE:" based on the updated bitmap
                if score_bitmap(block_y, block_x) = '1' then
                    obj_red <= "11"; -- White for text
                    obj_green <= "11";
                    obj_blue <= "11";
                else
                    obj_red <= "00"; -- Background color
                    obj_green <= "00";
                    obj_blue <= "00";
                end if;
            else
                -- Outside "SCORE:" display area
                obj_red <= "00";
                obj_green <= "00";
                obj_blue <= "00";
            end if;
        end if;
    end process;
end Behavioral;
