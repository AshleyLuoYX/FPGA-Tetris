-- Libraries and entity declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity game_logic is
    Port (
        clk         : in  std_logic;            -- Clock signal
        reset       : in  std_logic;            -- Reset signal
        move_left   : in  std_logic;            -- Move piece left
        move_right  : in  std_logic;            -- Move piece right
        rotate      : in  std_logic;            -- Rotate piece
        drop        : in  std_logic;            -- Hard drop
        board_state : out std_logic_vector(...);-- Current game board
        game_over   : out std_logic             -- Game over signal
    );
end game_logic;

architecture Behavioral of game_logic is

    -- Constants and Types
    constant ROWS : integer := 20;              -- Number of rows in the grid
    constant COLS : integer := 10;              -- Number of columns in the grid
    type Grid is array (0 to ROWS-1, 0 to COLS-1) of std_logic; -- Game grid

    -- Signals and Registers
    signal grid : Grid;                         -- Current game grid
    signal active_piece : std_logic_vector(...);-- Current active piece shape and rotation
    signal piece_pos_x : integer;               -- X position of the active piece
    signal piece_pos_y : integer;               -- Y position of the active piece
    signal line_clear : boolean;                -- Indicates if a line is cleared
    signal spawn_new_piece : boolean;           -- Flag to spawn a new piece

begin

    -- Game Loop Process
    game_process : process(clk, reset)
    begin
        if reset = '1' then
            -- Reset the game state
            grid <= (others => (others => '0'));  -- Clear the game grid
            piece_pos_x <= COLS / 2;             -- Center the piece horizontally
            piece_pos_y <= 0;                    -- Spawn at the top
            spawn_new_piece <= true;
            game_over <= '0';

        elsif rising_edge(clk) then
            if game_over = '0' then

                -- Handle Active Piece Movement
                if move_left = '1' then
                    if not collision_detected(piece_pos_x - 1, piece_pos_y, active_piece) then
                        piece_pos_x <= piece_pos_x - 1; -- Move left
                    end if;
                elsif move_right = '1' then
                    if not collision_detected(piece_pos_x + 1, piece_pos_y, active_piece) then
                        piece_pos_x <= piece_pos_x + 1; -- Move right
                    end if;
                end if;

                if rotate = '1' then
                    if not collision_detected(piece_pos_x, piece_pos_y, rotate_piece(active_piece)) then
                        active_piece <= rotate_piece(active_piece); -- Rotate piece
                    end if;
                end if;

                if drop = '1' or time_to_update_piece then
                    if not collision_detected(piece_pos_x, piece_pos_y + 1, active_piece) then
                        piece_pos_y <= piece_pos_y + 1; -- Move down
                    else
                        lock_piece(grid, piece_pos_x, piece_pos_y, active_piece); -- Lock piece in place
                        spawn_new_piece <= true;
                    end if;
                end if;

                -- Handle New Piece Spawn
                if spawn_new_piece = true then
                    if not spawn_new_active_piece(active_piece, piece_pos_x, piece_pos_y) then
                        game_over <= '1'; -- Game over if spawning fails
                    end if;
                    spawn_new_piece <= false;
                end if;

                -- Check for Line Clears
                if detect_and_clear_lines(grid) then
                    line_clear <= true; -- Indicate a line was cleared
                else
                    line_clear <= false;
                end if;

            end if; -- End of game_over check
        end if; -- End of clock edge
    end process;

    -- Output current grid state
    board_state <= serialize_grid(grid);

end Behavioral;

