# ==============================================================================
# SCRIPT DE SIMULACIÓN - FT245_IF
# Autor: Francisco Jesús Martín Lastre
# ==============================================================================

# 1. Preparación del entorno
restart
catch { remove_wave [get_waves *] }

add_wave clk
add_wave reset
add_wave wr_en
add_wave -color cyan ready

add_wave -color pink /FT245_IF/state_reg
add_wave TXEn
add_wave -color yellow /FT245_IF/TXEn_sync
add_wave -color lightpurple DIN
add_wave -color orange DATA
add_wave -color magenta WRn

# Reloj 100 MHz (Periodo 10ns)
add_force clk {1 0ns} {0 5ns} -repeat_every 10ns

# 1. Inicialización
add_force reset 1
add_force wr_en 0
add_force TXEn 1
add_force wr_en 1
run 5ns
add_force reset 0
run 10ns
add_force TXEn 0
run 10ns

# 2. Primer ciclo de escritura
add_force DIN -radix hex F1
run 15ns
add_force TXEn 1
run 15ns
add_force DIN -radix hex F2
run 25ns
add_force TXEn 0
run 35ns
add_force DIN -radix hex F3
run 10ns
add_force TXEn 1
run 35ns