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
        
        -- Periféricos de la placa Basys 3
        LED         : out STD_LOGIC_VECTOR(15 downto 0);
        SW          : in  STD_LOGIC_VECTOR(15 downto 0);
        CAT         : out STD_LOGIC_VECTOR(7 downto 0);
        AN          : out STD_LOGIC_VECTOR(3 downto 0)
    );
end TOP_FT245_Test;

architecture Behavioral of TOP_FT245_Test is

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

begin

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
    process(clk, reset)
    begin
        if reset = '1' then
            counter <= (others => '0');
            wr_prev <= '1';
        elsif rising_edge(clk) then
            if wr_prev = '0' and internal_WRn = '1' then
                counter <= counter + 1;
            end if;
            wr_prev <= internal_WRn;
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
    user_din  <= std_logic_vector(counter);
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