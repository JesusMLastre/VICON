------------------------------------------------------------------
-- Modulo TOP para proyecto VICON (Captura MT9V111 + UM232H)
-- Autor: Francisco Jesus Martin Lastre
------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TOP_FT245_Test is
    Port ( 
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        
        -- Interfaz fisica con UM232H
        FT245_D     : inout STD_LOGIC_VECTOR (7 downto 0);
        FT245_TXEn  : in  STD_LOGIC;
        FT245_RXFn  : in  STD_LOGIC;
        FT245_WRn   : out STD_LOGIC;
        FT245_RDn   : out STD_LOGIC;
        SIWU        : out STD_LOGIC;

        -- Camara MT9V111
        cam_xclk    : out STD_LOGIC;                     -- Reloj maestro de ~25 MHz hacia la camara
        cam_pclk    : in  STD_LOGIC;                     -- Reloj de pixel desde la camara
        cam_vsync   : in  STD_LOGIC;                     -- Sincronismo de fotograma (Frame Valid)
        cam_href    : in  STD_LOGIC;                     -- Sincronismo de linea (Line Valid)
        cam_data    : in  STD_LOGIC_VECTOR(7 downto 0);  -- Datos del pixel de la camara
        cam_rst_n   : out STD_LOGIC;                     -- Reset de la camara   
        
        -- Perifericos de la placa Basys 3
        LED         : out STD_LOGIC_VECTOR(15 downto 0);
        SW          : in  STD_LOGIC_VECTOR(15 downto 0);
        CAT         : out STD_LOGIC_VECTOR(7 downto 0);
        AN          : out STD_LOGIC_VECTOR(3 downto 0)
    );
end TOP_FT245_Test;

architecture Behavioral of TOP_FT245_Test is

    -- ==========================================
    -- DECLARACION DEL GENERADOR DE RELOJ (MMCM)
    -- ==========================================
    component clk_wiz_0
    port (
        clk_in1  : in  std_logic;
        clk_out1 : out std_logic;
        reset    : in  std_logic;
        locked   : out std_logic
    );
    end component;

    -- Señales internas para interactuar con el FT245_WR
    signal user_ready   : std_logic;
    signal user_wren    : std_logic;
    signal user_din     : std_logic_vector(7 downto 0);
    signal internal_WRn : std_logic;
    signal internal_DATA: std_logic_vector(7 downto 0);

    -- Señales internas para interactuar con el FT245_RD
    signal internal_RDn : std_logic;
    signal cmd_out      : std_logic_vector(7 downto 0);
    signal cmd_valid    : std_logic;

    -- Señales para el Antirrebote (Debouncer)
    signal reset_sync_1   : std_logic := '0';
    signal reset_sync_2   : std_logic := '0';
    signal reset_stable   : std_logic := '0';
    signal debounce_cnt : unsigned(20 downto 0) := (others => '0');

    -- Señales para el sincronizador 2-FF
    signal req_frame_100: std_logic := '0';
    signal sync_ff1     : std_logic := '0';
    signal req_frame_25 : std_logic := '0';

    -- Señales para Máquina de Estados de Captura
    type cap_state_t is (IDLE, WAIT_END_FRAME, WAIT_START_FRAME, CAPTURING, HANDSHAKE_END);
    signal cap_state : cap_state_t := IDLE;
    
    -- Señales para el Handshake (Confirmación de la cámara hacia el PC)
    signal frame_captured_25  : std_logic := '0';
    signal sync_ack1          : std_logic := '0';
    signal frame_captured_100 : std_logic := '0';

    -- Señal para la máquina de envío al PC
    type tx_state_t is (WAIT_READY, WAIT_BUSY);
    signal tx_state : tx_state_t := WAIT_READY;
    
    -- Señal para extraer Escala de Grises (Luminancia Y)
    signal byte_toggle        : std_logic := '0';
    
    -- ==========================================
    -- DECLARACION DE LA FIFO ASINCRONA
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

    -- Señales para el reloj y reset seguro de la cámara
    signal clk_locked    : std_logic;
    signal cam_rst_sync1 : std_logic := '0';
    signal cam_rst_sync2 : std_logic := '0';

    -- Señales para FSM de Handshake a 100 MHz
    type handshake_state_t is (WAIT_CMD, WAIT_ACK_HIGH, WAIT_ACK_LOW);
    signal hs_state : handshake_state_t := WAIT_CMD;

begin
    -- ==========================================
    -- SINCRONIZADOR DEL RESET DE LA CAMARA
    -- ==========================================
    process(clk, reset_stable)
    begin
        if reset_stable = '1' then
            cam_rst_sync1 <= '0';
            cam_rst_sync2 <= '0';
        elsif rising_edge(clk) then
            -- 'clk_locked' a 1 significa que los 25 MHz son 100% estables
            cam_rst_sync1 <= clk_locked;
            cam_rst_sync2 <= cam_rst_sync1;
        end if;
    end process;
    
    cam_rst_n <= cam_rst_sync2;

    -- ==========================================
    -- INSTANCIA DEL RELOJ DE LA CAMARA (25 MHz)
    -- ==========================================
    Inst_clk_wiz_camera: clk_wiz_0
    port map (
        clk_in1  => clk,       -- Reloj base de 100 MHz de la placa
        clk_out1 => cam_xclk,  -- Salida hacia el pin XCLK de la camara
        reset    => reset_stable,     -- Conectado al boton central BTNC
        locked   => clk_locked
    );

    -- ==========================================
    -- INSTANCIA DEL FT245 DE ESCRITURA
    -- ==========================================
    FT245_inst: entity work.FT245_WR
        port map (
            clk     => clk,
            reset   => reset_stable,
            DIN     => user_din,
            wr_en   => user_wren,
            ready   => user_ready,
            TXEn    => FT245_TXEn,
            WRn     => internal_WRn,
            DATA    => internal_DATA
        );

    -- ==========================================
    -- INSTANCIA DEL FT245 DE LECTURA
    -- ==========================================
    FT245_RX_inst: entity work.FT245_RD
        port map (
            clk       => clk,
            reset     => reset_stable,
            cmd_out   => cmd_out,
            cmd_valid => cmd_valid,
            RXFn      => FT245_RXFn,
            RDn       => internal_RDn,
            DATA      => FT245_D
        );

    -- ==========================================
    -- BLOQUE ANTIRREBOTE PARA RESET
    -- ==========================================
    process(clk)
    begin
        if rising_edge(clk) then
            reset_sync_1 <= reset;
            reset_sync_2 <= reset_sync_1;

            if reset_sync_2 = reset_stable then
                debounce_cnt <= (others => '0');
            else
                debounce_cnt <= debounce_cnt + 1;
                -- 2.000.000 ciclos a 100 MHz = 20 milisegundos
                if debounce_cnt = 2000000 then
                    reset_stable <= reset_sync_2;
                    debounce_cnt <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    -- ==========================================
    -- INSTANCIA DE LA FIFO DE PIXELES
    -- ==========================================
    Inst_fifo_cam: fifo_cam
      PORT MAP (
        rst    => reset_stable,
        wr_clk => cam_pclk,   -- Reloj de escritura: el que envia la camara
        rd_clk => clk,        -- Reloj de lectura: 100 MHz de la FPGA
        din    => fifo_din,
        wr_en  => fifo_wr_en,
        rd_en  => fifo_rd_en,
        dout   => fifo_dout,
        full   => fifo_full,
        empty  => fifo_empty
      );

    -- ==========================================
    -- DECODIFICADOR Y HANDSHAKE (Dominio 100 MHz)
    -- ==========================================
    process(clk, reset_stable)
    begin
        if reset_stable = '1' then
            req_frame_100      <= '0';
            sync_ack1          <= '0';
            frame_captured_100 <= '0';
            hs_state           <= WAIT_CMD;
        elsif rising_edge(clk) then
            -- 1. Sincronizamos el ACK de la cámara (25 MHz -> 100 MHz)
            sync_ack1          <= frame_captured_25;
            frame_captured_100 <= sync_ack1;

            -- 2. Máquina de Estados de Peticiones (FSM Handshake)
            case hs_state is
                when WAIT_CMD =>
                    req_frame_100 <= '0';
                    if cmd_valid = '1' and cmd_out = x"01" then
                        req_frame_100 <= '1';
                        hs_state      <= WAIT_ACK_HIGH;
                    end if;

                when WAIT_ACK_HIGH =>
                    req_frame_100 <= '1';
                    -- Esperamos a que la cámara capture el frame y lo reconozca
                    if frame_captured_100 = '1' then
                        req_frame_100 <= '0';
                        hs_state      <= WAIT_ACK_LOW;
                    end if;

                when WAIT_ACK_LOW =>
                    req_frame_100 <= '0';
                    -- Evitamos nuevas peticiones hasta que la señal caiga limpiamente
                    if frame_captured_100 = '0' then
                        hs_state <= WAIT_CMD;
                    end if;
            end case;
        end if;
    end process;
    
    -- ==========================================
    -- CAPTURA Y FSM (Dominio cam_pclk a ~25 MHz)
    -- ==========================================
    process(cam_pclk, reset_stable)
    begin
        if reset_stable = '1' then
            sync_ff1          <= '0';
            req_frame_25      <= '0';
            cap_state         <= IDLE;
            fifo_wr_en        <= '0';
            fifo_din          <= (others => '0');
            byte_toggle       <= '0';
            frame_captured_25 <= '0';
        elsif rising_edge(cam_pclk) then
            -- 1. Sincronizador 2-FF de la Petición (REQ) (100 MHz -> 25 MHz)
            sync_ff1     <= req_frame_100;
            req_frame_25 <= sync_ff1;

            -- Por defecto, no escribimos en la FIFO
            fifo_wr_en <= '0';

            -- 2. Máquina de Estados de Captura
            case cap_state is
                when IDLE =>
                    frame_captured_25 <= '0';
                    byte_toggle       <= '0';
                    
                    if req_frame_25 = '1' then
                        if cam_vsync = '1' then
                            cap_state <= WAIT_END_FRAME;   -- Ignorar frame a medias
                        else
                            cap_state <= WAIT_START_FRAME; -- Esperar a que empiece
                        end if;
                    end if;

                when WAIT_END_FRAME =>
                    -- Esperamos a que la señal de fotograma caiga a '0'
                    if cam_vsync = '0' then
                        cap_state <= WAIT_START_FRAME;
                    end if;

                when WAIT_START_FRAME =>
                    -- En cuanto asoma el flanco de subida del nuevo fotograma, capturamos
                    if cam_vsync = '1' then
                        cap_state   <= CAPTURING;
                    end if;

                when CAPTURING =>
                    if cam_vsync = '0' then
                        -- El fotograma ha terminado completamente
                        cap_state <= HANDSHAKE_END;
                    elsif cam_href = '1' then
                        -- Alternamos el toggle en cada ciclo de píxel válido
                        byte_toggle <= not byte_toggle;
                        
                        -- Extraemos la escala de grises (Descarte de Cb/Cr)
                        -- Como VHDL evalúa el valor ANTIGUO de la señal en este ciclo:
                        -- Reloj 1 (Dato Cb): byte_toggle evalúa a '0' -> No se graba
                        -- Reloj 2 (Dato Y):  byte_toggle evalúa a '1' -> SÍ se graba
                        if byte_toggle = '1' and fifo_full = '0' then
                            fifo_wr_en <= '1';
                            fifo_din   <= cam_data;
                        end if;
                    else
                        -- Reset al terminar cada línea horizontal
                        byte_toggle <= '0';
                    end if;

                when HANDSHAKE_END =>
                    -- Levantamos la confirmación (ACK) para el dominio de 100 MHz
                    frame_captured_25 <= '1';
                    
                    -- Esperamos pacientemente a que los 100 MHz bajen la petición
                    if req_frame_25 = '0' then
                        cap_state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

    -- ==========================================
    -- ENVIO HACIA EL PC (Dominio clk 100 MHz)
    -- ==========================================
    process(clk, reset_stable)
    begin
        if reset_stable = '1' then
            user_wren  <= '0';
            fifo_rd_en <= '0';
            tx_state   <= WAIT_READY;
        elsif rising_edge(clk) then
            -- Valores por defecto (pulsos limpios de 1 ciclo)
            fifo_rd_en <= '0';
            user_wren  <= '0';

            case tx_state is
                when WAIT_READY =>
                    -- Disparamos UN SOLO byte si todo está listo
                    if fifo_empty = '0' and user_ready = '1' then
                        fifo_rd_en <= '1';
                        user_wren  <= '1';
                        tx_state   <= WAIT_BUSY; -- Nos bloqueamos inmediatamente
                    end if;
                    
                when WAIT_BUSY =>
                    -- Esperamos pacientemente a que el módulo FT245 baje su señal "ready" 
                    -- para confirmar que ha procesado nuestro byte y no pisarnos.
                    if user_ready = '0' then
                        tx_state <= WAIT_READY;
                    end if;
            end case;
        end if;
    end process;

    -- ==========================================
    -- ASIGNACION DE SALIDAS DEL SISTEMA
    -- ==========================================
    -- Enviamos directamente el bus de salida de la FIFO a la interfaz FT245
    user_din  <= fifo_dout;
    
    FT245_WRn <= internal_WRn;
    FT245_D   <= internal_DATA when (internal_RDn = '1') else (others => 'Z');
    FT245_RDn <= internal_RDn; 
    SIWU      <= '1';
    
    LED(0)    <= FT245_TXEn;
    LED(1)    <= user_wren;
    LED(2)    <= reset_stable;
    LED(3)    <= fifo_empty;  -- Encendido = FIFO VACIA (No entran pixeles)
    LED(4)    <= fifo_full;   -- Encendido = FIFO LLENA
    LED(5)    <= user_ready;  -- Encendido = Interfaz FT245 lista
    LED(6)    <= cam_vsync;   -- Encendido = Sincronismo de fotograma activo
    LED(7)    <= cam_href;    -- Encendido = Sincronismo de linea activo

end Behavioral;