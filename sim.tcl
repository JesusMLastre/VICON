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
add_wave TXEn
add_wave -color lightpurple DIN
add_wave -color cyan ready
add_wave -color magenta WRn
add_wave DATA

add_wave -color yellow /FT245_IF/TXEn_sync
add_wave -color pink /FT245_IF/state_reg
add_wave -color teal /FT245_IF/state_next

# Reloj 100 MHz (Periodo 10ns)
add_force clk {1 0ns} {0 5ns} -repeat_every 10ns

# 1. Inicialización
add_force reset 1
add_force wr_en 0
add_force DIN -radix hex 00
add_force TXEn 1
add_force wr_en 1
run 23ns
add_force reset 0

# 2. Primer ciclo de escritura (Dato 0xAA)
add_force DIN -radix hex AA
run 10ns

# Activar TXEn (nivel bajo)
add_force TXEn 0
run 30ns 

# Restricción t6: WRn activo a TXEn inactivo (subida tras 20ns)
run 20ns
add_force TXEn 1

# 3. Segundo ciclo consecutivo (Dato 0xBB)
add_force DIN -radix hex BB

# Restricción t7: Tiempo de reposo TXEn (50ns)
run 28ns
add_force reset 1
run 26ns
add_force reset 0
add_force TXEn 0
run 60ns

# 4. Finalización de ráfaga
add_force wr_en 0
add_force TXEn 1
run 100ns