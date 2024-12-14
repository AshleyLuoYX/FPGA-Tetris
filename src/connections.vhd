library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.tetris_utils.all;

entity connections is
    Port (
        clk   : in  STD_LOGIC;
        raw_drop : in STD_LOGIC;
        raw_left : in std_logic;
        raw_right : in std_logic;
        raw_rotate : in std_logic;
        restart_game : in std_logic;
        red : out std_logic_vector(1 downto 0); -- VGA red signal
        green : out std_logic_vector(1 downto 0); -- VGA green signal
        blue : out std_logic_vector(1 downto 0); -- VGA blue signal
        hsync : out std_logic;                    -- Horizontal sync
        vsync : out std_logic;                     -- Vertical sync
        led : out std_logic_vector(1 downto 0)
    );
end connections;

architecture Behavioral of connections is

    signal debounced_left : std_logic := '0';
    signal debounced_right : std_logic := '0';
    signal debounced_rotate : std_logic := '0';
    signal debounced_drop : std_logic := '0';

    signal raddr1 : std_logic_vector(8 downto 0);
    signal raddr2 : std_logic_vector(8 downto 0);

    signal wen1 : std_logic;
    signal wen1_clear : std_logic;
    signal wen1_i : std_logic;

    signal wen2 : std_logic;
    signal wen2_clear : std_logic;
    signal wen2_i : std_logic;

    signal waddr1 : std_logic_vector(8 downto 0);
    signal waddr1_clear : std_logic_vector(8 downto 0);
    signal waddr1_i : std_logic_vector(8 downto 0);

    signal waddr2 : std_logic_vector(8 downto 0);
    signal waddr2_clear : std_logic_vector(8 downto 0);
    signal waddr2_i : std_logic_vector(8 downto 0);

    signal wpixel1 : std_logic;
    signal wpixel1_clear : std_logic;
    signal wpixel1_i : std_logic;

    signal wpixel2 : std_logic;
    signal wpixel2_clear : std_logic;
    signal wpixel2_i : std_logic;

    signal rpixel1 : std_logic;
    signal rpixel2 : std_logic;

    signal rpixel1_clear : std_logic;
    signal rpixel2_clear : std_logic;

    signal raddr1_clear : std_logic_vector(8 downto 0);
    signal raddr2_clear : std_logic_vector(8 downto 0);

    -- signal serialized_grid : std_logic_vector((ROWS * COLS) - 1 downto 0);
    signal serialized_grid : std_logic_vector((ROWS * COLS) - 1 downto 0);
    signal serialized_shadow : std_logic_vector((ROWS * COLS) - 1 downto 0);

    signal done : std_logic;
    signal lock : std_logic;
    signal game_over : std_logic;
    signal row_cleared : std_logic;

    component grid is
        Port (
            clk     : in  STD_LOGIC;
            raddr  : in  STD_LOGIC_VECTOR (8 downto 0);
            raddr_clear : in  STD_LOGIC_VECTOR (8 downto 0);
            wen     : in  STD_LOGIC;
            waddr   : in  STD_LOGIC_VECTOR (8 downto 0);
            wpixel  : in  STD_LOGIC;
            rpixel : out STD_LOGIC;
            rpixel_clear : out std_logic
        );
    end component;

    component top_level is
        Port (
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
            -- led : out std_logic_vector(1 downto 0);
            lock : out std_logic;
            done : in std_logic;
            game_over_sig : out std_logic;
            row_cleared : in std_logic
        );
    end component;

    component clear is 
        Port (
            clk    : in  STD_LOGIC;
            lock   : in  STD_LOGIC; -- signal raised when a block has done falling
            done   : out STD_LOGIC := '0';
            raddr_grid : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
            raddr_shadow : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
            rpixel_grid : out STD_LOGIC := '0';
            rpixel_shadow : out std_logic := '0';
            wen_grid : out STD_LOGIC := '0';
            wen_shadow : out STD_LOGIC := '0';
            wpixel1 : out STD_LOGIC := '0';
            wpixel2 : out STD_LOGIC := '0';
            waddr_grid : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
            waddr_shadow : out STD_LOGIC_VECTOR (8 downto 0) := (others => '0');
            row_cleared : out STD_LOGIC := '0'
            -- led : out std_logic_vector(1 downto 0)
        );
    end component;

begin
    wen1 <= wen1_i or wen1_clear; -- top_level or clear can write to grid
    wen2 <= wen2_i or wen2_clear;
    waddr1 <= waddr1_i or waddr1_clear; -- top_level or clear can write to grid
    waddr2 <= waddr2_i or waddr2_clear;
    wpixel1 <= wpixel1_i or wpixel1_clear; -- top_level or clear can write to grid
    wpixel2 <= wpixel2_i or wpixel2_clear;

    grid_inst : grid
    port map (
        clk     => clk,
        raddr  => raddr1,
        raddr_clear => raddr1_clear,
        wen     => wen1,
        waddr   => waddr1,
        wpixel  => wpixel1,
        rpixel => rpixel1,
        rpixel_clear => rpixel1_clear
    );

    shadow_inst : grid
    port map (
        clk     => clk,
        raddr  => raddr2,
        raddr_clear => raddr2_clear,
        wen     => wen2,
        waddr   => waddr2,
        wpixel  => wpixel2,
        rpixel => rpixel2,
        rpixel_clear => rpixel2_clear
    );

    top_level_inst : top_level
    port map (
        clk => clk,
        rpixel_grid => rpixel1,
        rpixel_shadow => rpixel2,
        raddr_grid => raddr1,
        raddr_shadow => raddr2,
        wen_grid => wen1_i,
        wen_shadow => wen2_i,
        wpixel_grid => wpixel1_i,
        wpixel_shadow => wpixel2_i,
        waddr_grid => waddr1_i,
        waddr_shadow => waddr2_i,
        drop => debounced_drop,
        left => debounced_left,
        right => debounced_right,
        rotate => debounced_rotate,
        restart_game => restart_game,
        serialized_grid => serialized_grid,
        serialized_shadow => serialized_shadow,
        done => done,
        lock => lock,
        game_over_sig => game_over,
        row_cleared => row_cleared
    );

    debounce_inst: entity work.debounce
    port map (
        clk   => clk,                -- System clock
        btn_r => raw_left,           -- Raw input for move left
        btn_b => raw_right,          -- Raw input for move right
        btn_y => raw_rotate,         -- Raw input for rotate
        btn_g => raw_drop,              -- Reset signal
        out_r => debounced_left,     -- Debounced move_left signal
        out_b => debounced_right,    -- Debounced move_right signal
        out_y => debounced_rotate,   -- Debounced rotate signal
        out_g => debounced_drop                -- Open if reset debounce isn't needed
    );

    vga_ctrl_inst: entity work.vga_controller_simple_tetris
    port map (
        clk   => clk,
        reset => '0',
        tx    => open,       -- Optional TX signal (unused here)
        grid  => serialized_grid, -- Serialized grid data
        -- grid_shadow => serialized_shadow,
        red   => red,             -- VGA red signal
        green => green,           -- VGA green signal
        blue  => blue,            -- VGA blue signal
        hsync => hsync,           -- VGA horizontal sync
        vsync => vsync, -- VGA vertical sync
        game_over => game_over
    );

    clear_inst: entity work.clear
    port map (
        lock  => lock,
        clk    => clk,
        done  => done,
        raddr_grid => raddr1_clear,
        raddr_shadow => raddr2_clear,
        rpixel_grid => rpixel1_clear,
        rpixel_shadow => rpixel2_clear,
        wen_grid => wen1_clear,
        wen_shadow => wen2_clear,
        wpixel1 => wpixel1_clear,
        wpixel2 => wpixel2_clear,
        waddr_grid => waddr1_clear,
        waddr_shadow => waddr2_clear,
        row_cleared => row_cleared
        -- led => led
    );

end Behavioral;
