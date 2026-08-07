library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_TOP is
-- Un testbench no tiene puertos
end tb_TOP;

architecture behavior of tb_TOP is

    -- Declaración del componente a probar (UUT)
    component TOP_FT245_Test
    Port ( 
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        FT245_D     : out STD_LOGIC_VECTOR (7 downto 0);
        FT245_TXEn  : in  STD_LOGIC;
        FT245_WRn   : out STD_LOGIC;
        FT245_RDn   : out STD_LOGIC;
        SIWU        : out STD_LOGIC;
        cam_xclk    : out STD_LOGIC;
        cam_pclk    : in  STD_LOGIC;
        cam_vsync   : in  STD_LOGIC;
        cam_href    : in  STD_LOGIC;
        cam_data    : in  STD_LOGIC_VECTOR(7 downto 0);
        LED         : out STD_LOGIC_VECTOR(15 downto 0);
        SW          : in  STD_LOGIC_VECTOR(15 downto 0);
        CAT         : out STD_LOGIC_VECTOR(7 downto 0);
        AN          : out STD_LOGIC_VECTOR(3 downto 0)
    );
    end component;

    -- Señales de entrada
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '1';
    signal FT245_TXEn : std_logic := '1'; -- '1' significa USB NO listo
    signal cam_pclk   : std_logic := '0';
    signal cam_vsync  : std_logic := '0';
    signal cam_href   : std_logic := '0';
    signal cam_data   : std_logic_vector(7 downto 0) := (others => '0');
    signal SW         : std_logic_vector(15 downto 0) := (others => '0');

    -- Señales de salida
    signal FT245_D    : std_logic_vector(7 downto 0);
    signal FT245_WRn  : std_logic;
    signal FT245_RDn  : std_logic;
    signal SIWU       : std_logic;
    signal cam_xclk   : std_logic;
    signal LED        : std_logic_vector(15 downto 0);
    signal CAT        : std_logic_vector(7 downto 0);
    signal AN         : std_logic_vector(3 downto 0);

    -- Definición de periodos de reloj
    constant clk_period  : time := 10 ns;  -- 100 MHz (Reloj placa)
    constant pclk_period : time := 40 ns;  -- 25 MHz (Reloj de píxel simulado)

begin

    -- Instanciación del módulo
    uut: TOP_FT245_Test PORT MAP (
        clk => clk, reset => reset,
        FT245_D => FT245_D, FT245_TXEn => FT245_TXEn, FT245_WRn => FT245_WRn,
        FT245_RDn => FT245_RDn, SIWU => SIWU,
        cam_xclk => cam_xclk, cam_pclk => cam_pclk,
        cam_vsync => cam_vsync, cam_href => cam_href, cam_data => cam_data,
        LED => LED, SW => SW, CAT => CAT, AN => AN
    );

    -- Generador del reloj principal (100 MHz)
    clk_process :process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- Generador del reloj de la cámara (25 MHz)
    pclk_process :process
    begin
        cam_pclk <= '0'; wait for pclk_period/2;
        cam_pclk <= '1'; wait for pclk_period/2;
    end process;

    -- Proceso de estímulos principales
    stim_proc: process
        variable pixel_val : unsigned(7 downto 0) := x"A1";
    begin		
        -- 1. Estado inicial
        reset <= '1';
        wait for 100 ns;	
        reset <= '0';
        wait for 100 ns;

        -- 2. Usuario activa el switch
        SW(0) <= '1';
        wait for 500 ns; -- Damos tiempo al antirrebote (¡bajado a 20 en TOP.vhd!)

        -- 3. El PC (UM232H) dice que está listo para recibir
        FT245_TXEn <= '0';
        wait for 200 ns;

        -- 4. SIMULACIÓN DE LA C�?MARA MT9V111
        cam_vsync <= '1'; -- Inicia fotograma
        wait for pclk_period * 3;
        
        -- Línea 1 (4 píxeles simulados)
        cam_href <= '1';
        for i in 0 to 3 loop
            cam_data <= std_logic_vector(pixel_val);
            pixel_val := pixel_val + 1;
            wait for pclk_period;
        end loop;
        cam_href <= '0';
        
        -- Blanking horizontal (pausa entre líneas)
        cam_data <= x"00";
        wait for pclk_period * 5; 
        
        -- Línea 2 (4 píxeles simulados)
        cam_href <= '1';
        for i in 0 to 3 loop
            cam_data <= std_logic_vector(pixel_val);
            pixel_val := pixel_val + 1;
            wait for pclk_period;
        end loop;
        cam_href <= '0';
        
        wait for pclk_period * 3;
        cam_vsync <= '0'; -- Fin del fotograma simulado

        -- Dejamos la simulación correr un poco más para ver cómo se vacía la FIFO
        wait for 1000 ns;
        wait;
    end process;

end behavior;