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