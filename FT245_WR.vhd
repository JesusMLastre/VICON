------------------------------------------------------------------
-- Autor: Francisco Jesus Martin Lastre
------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FT245_WR is
    Generic (
        -- Numero de FFs del sincronizador
        N: NATURAL := 2
    );
    Port ( 
        clk:    in STD_LOGIC;
        reset:  in STD_LOGIC;
        -- User IO ----------------------------
        DIN:    in STD_LOGIC_VECTOR(7 downto 0);
        wr_en:  in STD_LOGIC;
        ready:  out STD_LOGIC;
        -- FT245-like interface ---------------
        TXEn:   in STD_LOGIC;
        WRn:    out STD_LOGIC;
        DATA:   out STD_LOGIC_VECTOR(7 downto 0)
    );
end FT245_WR;

architecture Behavioral of FT245_WR is
    -- Sincronizador --------------------------
    -- Modelamos los dos FFs que conforman el sincronizador
    signal synchronizer: STD_LOGIC_VECTOR (N-1 downto 0);
    signal TXEn_sync:    std_logic;

    -- Estados de FSM
    type states is (idle, wait_for_TXE, output_data, write_1, write_2, write_3, write_4);
    signal state_reg, state_next: states;

    -- Salidas de FSM
    signal ready_reg, ready_next: std_logic;
    signal WRn_reg,   WRn_next  : std_logic;
    signal DATA_reg,  DATA_next : std_logic_vector(7 downto 0);
    
begin
    ------------------------------------------------------------------
    -- SINCRONIZADOR -------------------------------------------------
    SYNC: process (clk, reset)
    begin
        if reset = '1' then
            synchronizer <= (others => '1');
        elsif rising_edge(clk) then
            synchronizer <= TXEn & synchronizer(N-1 downto 1);
        end if;
    end process SYNC;
    TXEn_sync <= synchronizer(0);
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- REGISTRO DE ESTADO --------------------------------------------
    REG: process (clk, reset)
    begin
        if reset = '1' then
            state_reg <= idle;
            ready_reg <= '1';
            WRn_reg   <= '1';
            DATA_reg  <= (others=>'0');
        elsif rising_edge(clk) then
            state_reg <= state_next;
            ready_reg <= ready_next;
            WRn_reg   <= WRn_next;
            DATA_reg  <= DATA_next;
        end if;
    end process REG;
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- LOGICA DE ESTADO SIGUIENTE ---------------------------------------
    COMB: process (state_reg, wr_en, TXEn_sync, DIN, ready_reg, WRn_reg, DATA_reg)
    begin
        -- Asignaciones por defecto (para prevenir latches)
        state_next <= state_reg;
        ready_next <= ready_reg;
        WRn_next   <= WRn_reg;
        DATA_next  <= DATA_reg;
        case state_reg is
            -- Estado IDLE
            when idle =>
                if wr_en = '1' then
                    state_next <= wait_for_TXE;
                    ready_next <= '0';
                end if;
            
            -- Estado wait_for_TXE
            when wait_for_TXE =>
                if TXEn_sync = '0' then
                    state_next <= output_data;
                    DATA_next  <= DIN;
                end if;
            
            -- Estado output_data
            when output_data =>
                state_next <= write_1;
                WRn_next   <= '0';
            
            -- Estado write_1
            when write_1 =>
                state_next <= write_2;
            
            -- Estado write_2
            when write_2 =>
                state_next <= write_3;
            
            -- Estado write_3
            when write_3 =>
                state_next <= write_4;
            
            -- Estado write_4
            when write_4 =>                
                WRn_next   <= '1';
                if wr_en = '0' then
                    state_next <= idle;
                    ready_next <= '1';
                else
                    state_next <= wait_for_TXE;
                end if;
        end case;
    end process COMB;
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- CONEXIONES DE LAS SALIDAS
    ready <= ready_reg;
    WRn   <= WRn_reg;
    DATA  <= DATA_reg;
    ------------------------------------------------------------------

end Behavioral;