library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rom_tetrominos is
    Port (
        piece_index   : in  std_logic_vector(2 downto 0); -- 3-bit input for tetromino type (0 to 6)
        rotation      : in  std_logic_vector(1 downto 0); -- 2-bit input for rotation (0°, 90°, 180°, 270°)
        tetromino_out : out std_logic_vector(15 downto 0) -- 4x4 matrix output (16 bits)
    );
end rom_tetrominos;

architecture Behavioral of rom_tetrominos is
    -- ROM Data: Predefined tetromino shapes (4x4 matrices)
    type rom_type is array (0 to 6, 0 to 3) of std_logic_vector(15 downto 0);
    constant Tetromino_ROM : rom_type := (
        -- I Tetromino
        ("0100010001000100", "0000111100000000", "0010001000100010", "0000000011110000"),
        -- O Tetromino
        ("1100110000000000", "0011001100000000", "0000000000110011", "0000000011001100"),
        -- T Tetromino
        ("1110010000000000", "0001001100010000", "0000000000100111", "0000100011001000"),
        -- S Tetromino
        ("0110110000000000", "0010001100010000", "0000000000110110", "0000100011000100"),
        -- Z Tetromino
        ("1100011000000000", "0001001100100000", "0000000001100011", "0000010011001000"),
        -- L Tetromino
        ("0000100010001100", "1110100000000000", "0011000100010000", "0000000000010111"),
        -- J Tetromino
        ("0000000100010011", "0000000010001110", "1100100010000000", "0111000100000000")
    );
begin
    -- Output the corresponding tetromino shape based on inputs
    tetromino_out <= Tetromino_ROM(to_integer(unsigned(piece_index)), to_integer(unsigned(rotation)));
end Behavioral;
