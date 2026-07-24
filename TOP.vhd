----------------------------------------------------------------------------------
-- Módulo TOP para prueba de comunicación FT245 (Con Antirrebote)
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
        LED         : out STD_LOGIC_VECTOR(15 downto 0);
        SW          : in  STD_LOGIC_VECTOR(15 downto 0)
    );
end TOP_FT245_Test;

architecture Behavioral of TOP_FT245_Test is

    -- Señales internas para interactuar con el FT245_IF
    signal user_ready : std_logic;
    signal user_wren  : std_logic;
    signal user_din   : std_logic_vector(7 downto 0);
    
    -- Contador para generar datos de prueba
    signal counter    : unsigned(7 downto 0);
    -- Señal interna para recordar el valor de WRn en el ciclo anterior
    signal wr_prev : std_logic := '1';
    -- Señal espejo WRn
    signal internal_WRn: std_logic;
    signal internal_DATA: std_logic_vector(7 downto 0);

    -- ==========================================
    -- SEÑALES PARA EL ANTIRREBOTE (DEBOUNCER)
    -- ==========================================
    signal sw0_sync_1   : std_logic := '0';
    signal sw0_sync_2   : std_logic := '0';
    signal sw0_stable   : std_logic := '0';
    -- Contador de 21 bits para contar hasta 2.000.000 (20 ms a 100 MHz)
    signal debounce_cnt : unsigned(20 downto 0) := (others => '0');

begin

    -- Instancia de tu módulo de comunicación
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
            -- 1. Sincronizador de 2 etapas para evitar metaestabilidad
            sw0_sync_1 <= SW(0);
            sw0_sync_2 <= sw0_sync_1;

            -- 2. Lógica del contador
            if sw0_sync_2 = sw0_stable then
                debounce_cnt <= (others => '0');
            else
                debounce_cnt <= debounce_cnt + 1;
                -- Si la señal se mantiene estable durante 20 ms (2,000,000 ciclos a 100 MHz)
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
            -- Detección síncrona del flanco de subida (pasó de 0 a 1)
            if wr_prev = '0' and internal_WRn = '1' then
                counter <= counter + 1;
            end if;
            
            -- Actualizamos la memoria del estado anterior
            wr_prev <= internal_WRn;
        end if;
    end process;

    -- ==========================================
    -- ASIGNACIÓN DE SALIDAS
    -- ==========================================
    user_din <= std_logic_vector(counter);
    
    -- Asignamos la señal ESTABLE y limpia en lugar del interruptor físico
    user_wren <= sw0_stable;
    
    FT245_WRn <= internal_WRn;
    FT245_D   <= internal_DATA;
    
    -- Mantenemos la lectura desactivada
    FT245_RDn <= '1'; 
    
    LED(0)    <= FT245_TXEn;
    LED(1)    <= user_wren;
    LED(2)    <= reset;
    LED(3)    <= internal_WRn;
    LED(15)   <= internal_DATA(7);

end Behavioral;