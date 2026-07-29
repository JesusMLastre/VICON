----------------------------------------------------------------------------------
-- Módulo TOP para prueba de comunicación FT245 (Con Antirrebote y Display 7 Seg)
-- Autor: Francisco Jesús Martín Lastre
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TOP_FT245_Test is
    Port ( 
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        
        -- Interfaz física con UM232H
        FT245_D     : out STD_LOGIC_VECTOR (7 downto 0);
        FT245_TXEn  : in  STD_LOGIC;
        FT245_WRn   : out STD_LOGIC;
        FT245_RDn   : out STD_LOGIC;
        SIWU        : out STD_LOGIC;

        -- NUEVOS PUERTOS: Cámara MT9V111
        cam_xclk    : out STD_LOGIC;                     -- Reloj maestro de ~25 MHz hacia la cámara
        cam_pclk    : in  STD_LOGIC;                     -- Reloj de píxel desde la cámara
        cam_vsync   : in  STD_LOGIC;                     -- Sincronismo de fotograma (Frame Valid)
        cam_href    : in  STD_LOGIC;                     -- Sincronismo de línea (Line Valid)
        cam_data    : in  STD_LOGIC_VECTOR(7 downto 0);  -- Datos del píxel de la cámara
        
        -- Periféricos de la placa Basys 3
        LED         : out STD_LOGIC_VECTOR(15 downto 0);
        SW          : in  STD_LOGIC_VECTOR(15 downto 0);
        CAT         : out STD_LOGIC_VECTOR(7 downto 0);
        AN          : out STD_LOGIC_VECTOR(3 downto 0)
    );
end TOP_FT245_Test;

architecture Behavioral of TOP_FT245_Test is

    -- ==========================================
    -- DECLARACIÓN DEL GENERADOR DE RELOJ (MMCM)
    -- ==========================================
    component clk_wiz_0
    port (
        clk_in1  : in  std_logic;
        clk_out1 : out std_logic;
        reset    : in  std_logic;
        locked   : out std_logic
    );
    end component;

    -- Señales internas para interactuar con el FT245_IF
    signal user_ready : std_logic;
    signal user_wren  : std_logic;
    signal user_din   : std_logic_vector(7 downto 0);
    
    -- Contador para generar datos de prueba
    signal counter    : unsigned(7 downto 0);
    signal wr_prev    : std_logic := '1';
    signal internal_WRn: std_logic;
    signal internal_DATA: std_logic_vector(7 downto 0);

    -- Señales para el Antirrebote (Debouncer)
    signal sw0_sync_1   : std_logic := '0';
    signal sw0_sync_2   : std_logic := '0';
    signal sw0_stable   : std_logic := '0';
    signal debounce_cnt : unsigned(20 downto 0) := (others => '0');

    -- Señales para el control del Display de 7 Segmentos
    signal refresh_cnt  : unsigned(19 downto 0) := (others => '0');
    signal active_digit : std_logic_vector(1 downto 0);
    signal hex_val      : unsigned(3 downto 0);
    
    -- ==========================================
    -- DECLARACIÓN DE LA FIFO ASÍNCRONA
    -- ==========================================
    component fifo_cam
        PORT (
            rst    : IN STD_LOGIC;
            wr_clk : IN STD_LOGIC;
            rd_clk : IN STD_LOGIC;
            din    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            wr_en  : IN STD_LOGIC;
            rd_en  : IN STD_LOGIC;
            dout   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            full   : OUT STD_LOGIC;
            empty  : OUT STD_LOGIC
        );
    end component;

    -- Señales de la FIFO
    signal fifo_din   : std_logic_vector(7 downto 0);
    signal fifo_wr_en : std_logic;
    signal fifo_rd_en : std_logic;
    signal fifo_dout  : std_logic_vector(7 downto 0);
    signal fifo_full  : std_logic;
    signal fifo_empty : std_logic;

begin
    -- ==========================================
    -- INSTANCIA DEL RELOJ DE LA CÁMARA (25 MHz)
    -- ==========================================
    Inst_clk_wiz_camera: clk_wiz_0
    port map (
        clk_in1  => clk,       -- Reloj base de 100 MHz de la placa
        clk_out1 => cam_xclk,  -- Salida hacia el pin XCLK de la cámara
        reset    => reset,     -- Conectado al botón central BTNC
        locked   => open
    );

    -- Instancia del módulo de comunicación
    FT245_inst: entity work.FT245_IF
        port map (
            clk     => clk,
            reset   => reset,
            DIN     => user_din,
            wr_en   => user_wren,
            ready   => user_ready,
            TXEn    => FT245_TXEn,
            WRn     => internal_WRn,
            DATA    => internal_DATA
        );

    -- ==========================================
    -- BLOQUE ANTIRREBOTE PARA SW(0)
    -- ==========================================
    process(clk, reset)
    begin
        if reset = '1' then
            sw0_sync_1   <= '0';
            sw0_sync_2   <= '0';
            sw0_stable   <= '0';
            debounce_cnt <= (others => '0');
        elsif rising_edge(clk) then
            sw0_sync_1 <= SW(0);
            sw0_sync_2 <= sw0_sync_1;

            if sw0_sync_2 = sw0_stable then
                debounce_cnt <= (others => '0');
            else
                debounce_cnt <= debounce_cnt + 1;
                -- Estabilidad de 20 ms a 100 MHz
                if debounce_cnt = 2000000 then
                    sw0_stable <= sw0_sync_2;
                    debounce_cnt <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    -- ==========================================
    -- MÁQUINA GENERADORA DE DATOS DE PRUEBA
    -- ==========================================
    -- process(clk, reset)
    -- begin
    --     if reset = '1' then
    --         counter <= (others => '0');
    --         wr_prev <= '1';
    --     elsif rising_edge(clk) then
    --         if wr_prev = '0' and internal_WRn = '1' then
    --             counter <= counter + 1;
    --         end if;
    --         wr_prev <= internal_WRn;
    --     end if;
    -- end process;

    -- ==========================================
    -- INSTANCIA DE LA FIFO DE PÍXELES
    -- ==========================================
    Inst_fifo_cam: fifo_cam
      PORT MAP (
        rst    => reset,
        wr_clk => cam_pclk,   -- Reloj de escritura: el que envía la cámara
        rd_clk => clk,        -- Reloj de lectura: 100 MHz de la FPGA
        din    => fifo_din,
        wr_en  => fifo_wr_en,
        rd_en  => fifo_rd_en,
        dout   => fifo_dout,
        full   => fifo_full,
        empty  => fifo_empty
      );

    -- ==========================================
    -- 1. CAPTURA DE LA CÁMARA (Dominio cam_pclk)
    -- ==========================================
    process(cam_pclk, reset)
    begin
        if reset = '1' then
            fifo_wr_en <= '0';
            fifo_din   <= (others => '0');
        elsif rising_edge(cam_pclk) then
            -- Solo guardamos el dato si el fotograma y la línea son válidos
            if cam_vsync = '1' and cam_href = '1' and fifo_full = '0' then
                fifo_wr_en <= '1';
                fifo_din   <= cam_data;
            else
                fifo_wr_en <= '0';
            end if;
        end if;
    end process;

    -- ==========================================
    -- 2. ENVÍO HACIA EL PC (Dominio clk 100 MHz)
    -- ==========================================
    process(clk, reset)
    begin
        if reset = '1' then
            user_wren  <= '0';
            fifo_rd_en <= '0';
        elsif rising_edge(clk) then
            -- Valores por defecto para generar pulsos de un ciclo de reloj
            fifo_rd_en <= '0';
            user_wren  <= '0';

            -- Si hay píxeles en la FIFO, el switch está activado (antirrebote), y el módulo USB está listo
            if fifo_empty = '0' and user_ready = '1' and sw0_stable = '1' then
                fifo_rd_en <= '1';    -- Extraemos el píxel de la FIFO
                user_wren  <= '1';    -- Le decimos al FT245 que lo envíe
            end if;
        end if;
    end process;

    -- ==========================================
    -- CONTROL MULTIPLEXADO: DISPLAY 7 SEGMENTOS
    -- ==========================================
    
    -- 1. Contador para la frecuencia de refresco (~380 Hz)
    process(clk, reset)
    begin
        if reset = '1' then
            refresh_cnt <= (others => '0');
        elsif rising_edge(clk) then
            refresh_cnt <= refresh_cnt + 1;
        end if;
    end process;
    
    -- Usamos los bits superiores para seleccionar qué display está encendido
    active_digit <= std_logic_vector(refresh_cnt(19 downto 18));
    
    -- 2. Selección del ánodo y del medio byte (nibble) del contador
    process(active_digit, counter)
    begin
        -- Por defecto: displays apagados y valor cero
        AN <= "1111";
        hex_val <= "0000";
        
        case active_digit is
            when "00" => 
                AN <= "1110"; -- Activa el display 0 (el de más a la derecha)
                hex_val <= counter(3 downto 0); -- Parte baja del contador
            when "01" => 
                AN <= "1101"; -- Activa el display 1
                hex_val <= counter(7 downto 4); -- Parte alta del contador
            when others => 
                AN <= "1111"; -- Los displays 2 y 3 permanecen apagados ("XX")
                hex_val <= "0000";
        end case;
    end process;

    -- 3. Decodificador de Hexadecimal a 7 Segmentos
    process(hex_val, active_digit)
    begin
        -- Si estamos en un dígito inactivo (displays 2 y 3), apagamos todos los segmentos
        if active_digit = "10" or active_digit = "11" then
            CAT <= "11111111"; 
        else
            -- Lógica para los dígitos activos (Cátodo común: 0 enciende, 1 apaga)
            -- Orden de CAT[7:0]: DP, G, F, E, D, C, B, A
            case hex_val is
                when x"0" => CAT <= "11000000";
                when x"1" => CAT <= "11111001";
                when x"2" => CAT <= "10100100";
                when x"3" => CAT <= "10110000";
                when x"4" => CAT <= "10011001";
                when x"5" => CAT <= "10010010";
                when x"6" => CAT <= "10000010";
                when x"7" => CAT <= "11111000";
                when x"8" => CAT <= "10000000";
                when x"9" => CAT <= "10010000";
                when x"A" => CAT <= "10001000";
                when x"B" => CAT <= "10000011";
                when x"C" => CAT <= "11000110";
                when x"D" => CAT <= "10100001";
                when x"E" => CAT <= "10000110";
                when x"F" => CAT <= "10001110";
                when others => CAT <= "11111111";
            end case;
        end if;
    end process;

    -- ==========================================
    -- ASIGNACIÓN DE SALIDAS DEL SISTEMA
    -- ==========================================
    --user_din  <= std_logic_vector(counter);
    user_din  <= fifo_dout;
    user_wren <= sw0_stable;
    
    FT245_WRn <= internal_WRn;
    FT245_D   <= internal_DATA;
    FT245_RDn <= '1'; 
    SIWU      <= '1';
    
    LED(0)    <= FT245_TXEn;
    LED(1)    <= user_wren;
    LED(2)    <= reset;
    LED(3)    <= internal_WRn;
    LED(4)    <= user_ready;
    LED(15)   <= internal_DATA(7);

end Behavioral;