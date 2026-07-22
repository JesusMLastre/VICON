----------------------------------------------------------------------------------
-- M?dulo TOP para prueba de comunicaci?n FT245
-- Autor: Francisco Jes?s Mart?n Lastre
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TOP_FT245_Test is
    Port ( 
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        
        -- Interfaz f?sica con UM232H
        FT245_D     : out STD_LOGIC_VECTOR (7 downto 0);
        FT245_TXEn  : in  STD_LOGIC;
        FT245_WRn   : out STD_LOGIC;
        FT245_RDn   : out STD_LOGIC;
        LED         : out STD_LOGIC_VECTOR(15 downto 0)
    );
end TOP_FT245_Test;

architecture Behavioral of TOP_FT245_Test is

    -- Se?ales internas para interactuar con el FT245_IF
    signal user_ready : std_logic;
    signal user_wren  : std_logic;
    signal user_din   : std_logic_vector(7 downto 0);
    
    -- Contador para generar datos de prueba
    signal counter    : unsigned(7 downto 0);
    -- Se?al interna para recordar el valor de WRn en el ciclo anterior
    signal wr_prev : std_logic := '1';
    -- Se?al espejo WRn
    signal internal_WRn: std_logic;
    signal internal_DATA: std_logic_vector(7 downto 0);

begin

    -- Instancia de tu m?dulo de comunicaci?n
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

    -- M?quina generadora de datos de prueba (Modo R?faga)
    process(clk, reset)
    begin
        if reset = '1' then
            counter <= (others => '0');
            wr_prev <= '1';
        elsif rising_edge(clk) then
            -- 2. Detecci?n s?ncrona del flanco de subida (pas? de 0 a 1)
            if wr_prev = '0' and internal_WRn = '1' then
                counter <= counter + 1;
            end if;
            
            -- 1. Actualizamos la memoria del estado anterior
            wr_prev <= internal_WRn;
        end if;
    end process;

    -- Conexi?n del contador al bus de entrada de datos
    user_din <= std_logic_vector(counter);
    -- Forzamos la habilitaci?n de escritura SIEMPRE a '1' para el modo r?faga continuo
    user_wren <= '1';
    FT245_WRn <= internal_WRn;
    FT245_D <= internal_DATA;
    -- Mantenemos la lectura desactivada
    FT245_RDn <= '1'; 
    LED(0)    <= FT245_TXEn;
    LED(1)    <= user_wren;
    LED(2)    <= reset;
    LED(3)    <= internal_WRn;
    LED(15)   <= internal_DATA(7);
end Behavioral;