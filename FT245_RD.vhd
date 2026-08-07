------------------------------------------------------------------
-- Modulo: FT245_RD (Recepcion de Comandos)
-- Descripcion: Maquina de estados analoga a FT245_WR para lectura
------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FT245_RD is
    Generic (
        -- Numero de FFs del sincronizador
        N: NATURAL := 2
    );
    Port ( 
        clk       : in STD_LOGIC;
        reset     : in STD_LOGIC;
        -- Interfaz de Usuario (Hacia la FPGA) ----------
        cmd_out   : out STD_LOGIC_VECTOR(7 downto 0);
        cmd_valid : out STD_LOGIC;
        -- Interfaz FT245 -------------------------------
        RXFn      : in STD_LOGIC;
        RDn       : out STD_LOGIC;
        DATA      : in STD_LOGIC_VECTOR(7 downto 0)
    );
end FT245_RD;

architecture Behavioral of FT245_RD is
    ------------------------------------------------------------------
    -- SINCRONIZADOR 
    ------------------------------------------------------------------
    signal synchronizer : STD_LOGIC_VECTOR (N-1 downto 0);
    signal RXFn_sync    : std_logic;

    -- Estados de FSM analogos a la escritura
    type states is (idle, read_1, read_2, read_3, wait_recovery);
    signal state_reg, state_next: states;

    -- Salidas de FSM registradas
    signal RDn_reg,       RDn_next       : std_logic;
    signal cmd_out_reg,   cmd_out_next   : std_logic_vector(7 downto 0);
    signal cmd_valid_reg, cmd_valid_next : std_logic;
    
begin
    ------------------------------------------------------------------
    -- 1. PROCESO DE SINCRONIZACION (Evita Metaestabilidad)
    ------------------------------------------------------------------
    SYNC: process (clk, reset)
    begin
        if reset = '1' then
            synchronizer <= (others => '1');
        elsif rising_edge(clk) then
            synchronizer <= RXFn & synchronizer(N-1 downto 1);
        end if;
    end process SYNC;
    -- Usamos la se�al sincronizada y segura para nuestra FSM
    RXFn_sync <= synchronizer(0); 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 2. REGISTRO DE ESTADO Y SALIDAS
    ------------------------------------------------------------------
    REG: process (clk, reset)
    begin
        if reset = '1' then
            state_reg     <= idle;
            RDn_reg       <= '1';
            cmd_out_reg   <= (others => '0');
            cmd_valid_reg <= '0';
        elsif rising_edge(clk) then
            state_reg     <= state_next;
            RDn_reg       <= RDn_next;
            cmd_out_reg   <= cmd_out_next;
            cmd_valid_reg <= cmd_valid_next;
        end if;
    end process REG;
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 3. LOGICA DE ESTADO SIGUIENTE (Maquina de Moore/Mealy)
    ------------------------------------------------------------------
    COMB: process (state_reg, RXFn_sync, DATA, RDn_reg, cmd_out_reg)
    begin
        -- Asignaciones por defecto
        state_next     <= state_reg;
        RDn_next       <= RDn_reg;
        cmd_out_next   <= cmd_out_reg;
        cmd_valid_next <= '0'; -- Por defecto a 0 para generar un pulso limpio

        case state_reg is
            when idle =>
                RDn_next <= '1';
                if RXFn_sync = '0' then
                    state_next <= read_1;
                    RDn_next   <= '0'; -- Bajamos RD# para iniciar la lectura
                end if;
            
            -- Los estados read_1, 2, 3 y 4 mantienen RD# a '0' durante 40ns
            -- Asegurando cumplir el requisito T4 (minimo 30ns) de los apuntes
            when read_1 =>
                state_next <= read_2;
            
            when read_2 =>
                state_next <= read_3;
            
            when read_3 =>
                -- El dato ya es estable (T3 es max 14ns). Lo capturamos.
                cmd_out_next   <= DATA; 
                cmd_valid_next <= '1';  -- Disparamos el pulso
                RDn_next       <= '1';  -- Levantamos RD# finalizando el ciclo
                state_next     <= wait_recovery;
                
            when wait_recovery =>
                -- Esperamos a que el chip USB vuelva a subir RXF# a '1', 
                -- confirmando que ha terminado de procesar nuestra lectura.
                if RXFn_sync = '1' then
                    state_next <= idle;
                end if;
        end case;
    end process COMB;
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 4. CONEXIONES DE LAS SALIDAS
    ------------------------------------------------------------------
    RDn       <= RDn_reg;
    cmd_out   <= cmd_out_reg;
    cmd_valid <= cmd_valid_reg;

end Behavioral;