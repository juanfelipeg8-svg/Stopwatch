LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY stopwatch_top IS

    GENERIC (
        CLK_HZ : INTEGER := 50_000_000
    );

    PORT (
        clk       : IN  STD_LOGIC;
        go        : IN  STD_LOGIC;

        -- Pushbuttons de la DE0: activos en bajo
        syn_clr_n : IN  STD_LOGIC;
        rst_n     : IN  STD_LOGIC;

        HEX0_D  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1_D  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2_D  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX3_D  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);

        HEX0_DP : OUT STD_LOGIC;
        HEX1_DP : OUT STD_LOGIC;
        HEX2_DP : OUT STD_LOGIC;
        HEX3_DP : OUT STD_LOGIC
    );

END ENTITY;


ARCHITECTURE structural OF stopwatch_top IS

    ------------------------------------------------------------
    -- DIVISOR DE FRECUENCIA
    ------------------------------------------------------------

    CONSTANT DIV_N : INTEGER := 23;

    CONSTANT DIV_MAX_INT : INTEGER :=
        (CLK_HZ / 10) - 1;

    CONSTANT ZERO_DIV :
        STD_LOGIC_VECTOR(DIV_N-1 DOWNTO 0) :=
        (OTHERS => '0');

    CONSTANT MAX_DIV :
        STD_LOGIC_VECTOR(DIV_N-1 DOWNTO 0) :=
        STD_LOGIC_VECTOR(
            TO_UNSIGNED(DIV_MAX_INT, DIV_N)
        );


    ------------------------------------------------------------
    -- VALORES PARA LOS CONTADORES BCD
    ------------------------------------------------------------

    CONSTANT ZERO4 :
        STD_LOGIC_VECTOR(3 DOWNTO 0) :=
        "0000";

    CONSTANT NINE4 :
        STD_LOGIC_VECTOR(3 DOWNTO 0) :=
        "1001";


    ------------------------------------------------------------
    -- SEÑALES DE CONTROL
    ------------------------------------------------------------

    SIGNAL rst_i     : STD_LOGIC;
    SIGNAL syn_clr_i : STD_LOGIC;


    ------------------------------------------------------------
    -- DIVISOR 0.1 s
    ------------------------------------------------------------

    SIGNAL div_count  :
        STD_LOGIC_VECTOR(DIV_N-1 DOWNTO 0);

    SIGNAL tick_100ms :
        STD_LOGIC;


    ------------------------------------------------------------
    -- DIGITOS DEL CRONOMETRO
    ------------------------------------------------------------

    SIGNAL decimas :
        STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL unidades :
        STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL decenas :
        STD_LOGIC_VECTOR(3 DOWNTO 0);


    ------------------------------------------------------------
    -- CARRY / MAX TICK
    ------------------------------------------------------------

    SIGNAL tick_decimas  : STD_LOGIC;
    SIGNAL tick_unidades : STD_LOGIC;


    ------------------------------------------------------------
    -- ENABLES
    ------------------------------------------------------------

    SIGNAL ena_div      : STD_LOGIC;
    SIGNAL ena_decimas  : STD_LOGIC;
    SIGNAL ena_unidades : STD_LOGIC;
    SIGNAL ena_decenas  : STD_LOGIC;


BEGIN


    ------------------------------------------------------------
    -- LOS BOTONES DE LA DE0 SON ACTIVOS EN BAJO
    ------------------------------------------------------------

    rst_i     <= NOT rst_n;
    syn_clr_i <= NOT syn_clr_n;


    ------------------------------------------------------------
    -- ENABLES
    ------------------------------------------------------------

    -- El divisor se congela cuando GO = 0.
    -- syn_clr se agrega para permitir borrar incluso pausado.

    ena_div <=
        go OR syn_clr_i;


    -- Decimas: avanzan cada 0.1 s

    ena_decimas <=
        (go AND tick_100ms)
        OR syn_clr_i;


    -- Unidades: avanzan cuando las decimas estaban en 9

    ena_unidades <=
        (go AND tick_100ms AND tick_decimas)
        OR syn_clr_i;


    -- Decenas: avanzan cuando tenemos x9.9

    ena_decenas <=
        (go AND tick_100ms
            AND tick_decimas
            AND tick_unidades)
        OR syn_clr_i;


    ------------------------------------------------------------
    -- DIVISOR DE 50 MHz
    --
    -- 50 000 000 Hz / 10 = 5 000 000 pulsos
    --
    -- Cuenta:
    -- 0 ... 4 999 999
    --
    -- max_tick produce el evento de 0.1 s
    ------------------------------------------------------------

    DIVISOR_01S : ENTITY WORK.contador_uni

        GENERIC MAP (
            N => DIV_N
        )

        PORT MAP (
            clk      => clk,
            rst      => rst_i,
            ena      => ena_div,
            syn_clr  => syn_clr_i,

            ini      => ZERO_DIV,
            up       => '1',
            max      => MAX_DIV,

            max_tick => tick_100ms,
            counter  => div_count
        );


    ------------------------------------------------------------
    -- CONTADOR DE DECIMAS
    --
    -- 0,1,2,...,9,0
    ------------------------------------------------------------

    CONT_DECIMAS : ENTITY WORK.contador_uni

        GENERIC MAP (
            N => 4
        )

        PORT MAP (
            clk      => clk,
            rst      => rst_i,
            ena      => ena_decimas,
            syn_clr  => syn_clr_i,

            ini      => ZERO4,
            up       => '1',
            max      => NINE4,

            max_tick => tick_decimas,
            counter  => decimas
        );


    ------------------------------------------------------------
    -- CONTADOR DE UNIDADES
    ------------------------------------------------------------

    CONT_UNIDADES : ENTITY WORK.contador_uni

        GENERIC MAP (
            N => 4
        )

        PORT MAP (
            clk      => clk,
            rst      => rst_i,
            ena      => ena_unidades,
            syn_clr  => syn_clr_i,

            ini      => ZERO4,
            up       => '1',
            max      => NINE4,

            max_tick => tick_unidades,
            counter  => unidades
        );


    ------------------------------------------------------------
    -- CONTADOR DE DECENAS
    ------------------------------------------------------------

    CONT_DECENAS : ENTITY WORK.contador_uni

        GENERIC MAP (
            N => 4
        )

        PORT MAP (
            clk      => clk,
            rst      => rst_i,
            ena      => ena_decenas,
            syn_clr  => syn_clr_i,

            ini      => ZERO4,
            up       => '1',
            max      => NINE4,

            max_tick => OPEN,
            counter  => decenas
        );


    ------------------------------------------------------------
    -- DISPLAYS
    --
    -- HEX2 HEX1 . HEX0
    --
    --   0    0  .  0
    ------------------------------------------------------------

    DISP_DECIMAS : ENTITY WORK.hex7seg

        PORT MAP (
            x   => decimas,
            seg => HEX0_D
        );


    DISP_UNIDADES : ENTITY WORK.hex7seg

        PORT MAP (
            x   => unidades,
            seg => HEX1_D
        );


    DISP_DECENAS : ENTITY WORK.hex7seg

        PORT MAP (
            x   => decenas,
            seg => HEX2_D
        );


    ------------------------------------------------------------
    -- HEX3 APAGADO
    ------------------------------------------------------------

    HEX3_D <= (OTHERS => '1');


    ------------------------------------------------------------
    -- PUNTOS DECIMALES
    --
    -- HEX2 HEX1.HEX0
    --
    -- El punto decimal también es activo en bajo.
    ------------------------------------------------------------

    HEX0_DP <= '1';
    HEX1_DP <= '0';
    HEX2_DP <= '1';
    HEX3_DP <= '1';


END ARCHITECTURE;