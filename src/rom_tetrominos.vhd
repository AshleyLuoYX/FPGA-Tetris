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
        ("0000111100000000", "0010001000100010", "0000111100000000", "0010001000100010"),
        -- O Tetromino
        ("1100110000000000", "1100110000000000", "1100110000000000", "1100110000000000"),
        -- T Tetromino
        ("0110111000000000", "0100111001000000", "1110011000000000", "0100111001000000"),
        -- S Tetromino
        ("0110011000000000", "0100110010000000", "0110011000000000", "0100110010000000"),
        -- Z Tetromino
        ("1100011000000000", "0100111000100000", "1100011000000000", "0100111000100000"),
        -- L Tetromino
        ("0010111100000000", "0110010001000000", "1110100000000000", "0010001000110000"),
        -- J Tetromino
        ("1000111100000000", "0100010001100000", "1110001000000000", "0110010001000000")
    );
begin
    -- Output the corresponding tetromino shape based on inputs
    tetromino_out <= Tetromino_ROM(to_integer(unsigned(piece_index)), to_integer(unsigned(rotation)));
end Behavioral;
