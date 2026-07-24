# ==============================================================================
# Archivo XDC - Proyecto VICON (Prueba FT245)
# ==============================================================================

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# 1. Señal de Reloj (100 MHz)
set_property PACKAGE_PIN W5 [get_ports clk]							
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# 2. Reset (Botón central BTNC)
set_property PACKAGE_PIN U18 [get_ports reset]						
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# 3. Interfaz FT245 - Bus de Datos (PMOD JB)
set_property PACKAGE_PIN A14 [get_ports {FT245_D[0]}]					
set_property PACKAGE_PIN A15 [get_ports {FT245_D[1]}]					
set_property PACKAGE_PIN A16 [get_ports {FT245_D[2]}]					
set_property PACKAGE_PIN A17 [get_ports {FT245_D[3]}]					
set_property PACKAGE_PIN B15 [get_ports {FT245_D[4]}]					
set_property PACKAGE_PIN C15 [get_ports {FT245_D[5]}]					
set_property PACKAGE_PIN B16 [get_ports {FT245_D[6]}]					
set_property PACKAGE_PIN C16 [get_ports {FT245_D[7]}]					
set_property IOSTANDARD LVCMOS33 [get_ports {FT245_D[*]}]

# 4. Interfaz FT245 - Bus de Control (PMOD JC)
# C1 - TXE (Entrada)
set_property PACKAGE_PIN L17 [get_ports FT245_TXEn]					
set_property IOSTANDARD LVCMOS33 [get_ports FT245_TXEn]

# C3 - WR (Salida)
set_property PACKAGE_PIN M19 [get_ports FT245_WRn]					
set_property IOSTANDARD LVCMOS33 [get_ports FT245_WRn]

# C2 - RD (Salida)
set_property PACKAGE_PIN M18 [get_ports FT245_RDn]
set_property IOSTANDARD LVCMOS33 [get_ports FT245_RDn]

# Nota: RXF (C0, pin K17) y RD (C2, pin M18) no se declaran aún porque
# el módulo actual FT245_IF solo soporta transmisión hacia el PC.

## --- LEDS ---
## Asigna los 16 LEDs situados encima de los interruptores a los puertos LED[0] a LED[15].

set_property PACKAGE_PIN U16 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property PACKAGE_PIN E19 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property PACKAGE_PIN U19 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property PACKAGE_PIN V19 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]
set_property PACKAGE_PIN W18 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property PACKAGE_PIN U15 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property PACKAGE_PIN U14 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property PACKAGE_PIN V14 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
set_property PACKAGE_PIN V13 [get_ports {LED[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[8]}]
set_property PACKAGE_PIN V3 [get_ports {LED[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[9]}]
set_property PACKAGE_PIN W3 [get_ports {LED[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[10]}]
set_property PACKAGE_PIN U3 [get_ports {LED[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[11]}]
set_property PACKAGE_PIN P3 [get_ports {LED[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[12]}]
set_property PACKAGE_PIN N3 [get_ports {LED[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[13]}]
set_property PACKAGE_PIN P1 [get_ports {LED[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[14]}]
set_property PACKAGE_PIN L1 [get_ports {LED[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[15]}]

## --- INTERRUPTORES (SWITCHES) ---
## Asigna los 16 interruptores deslizantes de la placa a los puertos SW[0] a SW[15].
## Se define la ubicaci?n f?sica (PIN) y el nivel de voltaje (LVCMOS33).

set_property PACKAGE_PIN V17 [get_ports {SW[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[0]}]
set_property PACKAGE_PIN V16 [get_ports {SW[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[1]}]
set_property PACKAGE_PIN W16 [get_ports {SW[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[2]}]
set_property PACKAGE_PIN W17 [get_ports {SW[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[3]}]
set_property PACKAGE_PIN W15 [get_ports {SW[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[4]}]
set_property PACKAGE_PIN V15 [get_ports {SW[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[5]}]
set_property PACKAGE_PIN W14 [get_ports {SW[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[6]}]
set_property PACKAGE_PIN W13 [get_ports {SW[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[7]}]
set_property PACKAGE_PIN V2 [get_ports {SW[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[8]}]
set_property PACKAGE_PIN T3 [get_ports {SW[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[9]}]
set_property PACKAGE_PIN T2 [get_ports {SW[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[10]}]
set_property PACKAGE_PIN R3 [get_ports {SW[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[11]}]
set_property PACKAGE_PIN W2 [get_ports {SW[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[12]}]
set_property PACKAGE_PIN U1 [get_ports {SW[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[13]}]
set_property PACKAGE_PIN T1 [get_ports {SW[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[14]}]
set_property PACKAGE_PIN R2 [get_ports {SW[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[15]}]

## --- DISPLAY 7 SEGMENTOS (C?TODOS) ---
## Controla los segmentos individuales (A, B, C, D, E, F, G y punto decimal) del display.
## Al ser c?todo com?n, un '0' l?gico enciende el segmento.

set_property PACKAGE_PIN W7 [get_ports {CAT[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CAT[0]}]
set_property PACKAGE_PIN W6 [get_ports {CAT[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CAT[1]}]
set_property PACKAGE_PIN U8 [get_ports {CAT[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CAT[2]}]
set_property PACKAGE_PIN V8 [get_ports {CAT[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CAT[3]}]
set_property PACKAGE_PIN U5 [get_ports {CAT[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CAT[4]}]
set_property PACKAGE_PIN V5 [get_ports {CAT[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CAT[5]}]
set_property PACKAGE_PIN U7 [get_ports {CAT[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CAT[6]}]
set_property PACKAGE_PIN V7 [get_ports {CAT[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CAT[7]}]

## --- DISPLAY 7 SEGMENTOS (?NODOS) ---
## Selecciona cu?l de los 4 d?gitos del display est? activo.

set_property PACKAGE_PIN U2 [get_ports {AN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[0]}]
set_property PACKAGE_PIN U4 [get_ports {AN[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[1]}]
set_property PACKAGE_PIN V4 [get_ports {AN[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[2]}]
set_property PACKAGE_PIN W4 [get_ports {AN[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[3]}]