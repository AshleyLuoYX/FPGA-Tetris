library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity title_generator is
    port (
        clk       : in std_logic;                  -- System clock
        hcount    : in unsigned(9 downto 0);       -- Horizontal pixel counter
        vcount    : in unsigned(9 downto 0);       -- Vertical pixel counter
        obj_red   : out std_logic_vector(1 downto 0); -- Red color signal
        obj_green : out std_logic_vector(1 downto 0); -- Green color signal
        obj_blue  : out std_logic_vector(1 downto 0)  -- Blue color signal
    );
end title_generator;

architecture Behavioral of title_generator is
    -- Title display area (right side of the grid)
    constant title_start_x : integer := 300;  -- Starting X coordinate for the title
    constant title_start_y : integer := 30;   -- Starting Y coordinate for the title
    constant block_size : integer := 12;       -- Enlargement factor (8x8 pixels per block)

    -- Binary representation of the title
    type title_array is array (0 to 4, 0 to 23) of std_logic;
    constant title_bitmap : title_array := (
        -- "TETRIS" in binary, each character is 5 rows by 24 columns
        "111011110111011100100111",
        "010010000010010010101000",
        "010011100010011100100110",
        "010010000010010100100001",
        "010011110010010010101110"
    );

    signal title_x, title_y : integer; -- Current pixel position relative to the title
    signal block_x, block_y : integer; -- Block coordinates within the enlarged title
    signal cell_x, cell_y : integer;   -- Position within a single 8x8 block
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Calculate pixel position relative to the title's starting position
            title_x <= to_integer(hcount) - title_start_x;
            title_y <= to_integer(vcount) - title_start_y;

            -- Calculate block coordinates (5x24 grid)
            block_x <= title_x / block_size; -- Horizontal block index
            block_y <= title_y / block_size; -- Vertical block index

            -- Calculate position within the current block (8x8 pixels)
            cell_x <= title_x mod block_size;
            cell_y <= title_y mod block_size;

            -- Check if within title display area
            if (hcount >= to_unsigned(title_start_x, 10)) and
               (hcount < to_unsigned(title_start_x + (24 * block_size), 10)) and -- 24 columns * 8 pixels per block
               (vcount >= to_unsigned(title_start_y, 10)) and
               (vcount < to_unsigned(title_start_y + (5 * block_size), 10)) then -- 5 rows * 8 pixels per block

                -- Render title based on the bitmap
                if title_bitmap(block_y, block_x) = '1' then
                    obj_red <= "11"; -- White for title
                    obj_green <= "11";
                    obj_blue <= "11";
                else
                    obj_red <= "00"; -- Background color
                    obj_green <= "00";
                    obj_blue <= "00";
                end if;
            else
                -- Outside title display area
                obj_red <= "00";
                obj_green <= "00";
                obj_blue <= "00";
            end if;
        end if;
    end process;
end Behavioral;
