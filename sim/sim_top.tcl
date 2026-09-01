# ==============================================================================
# SCRIPT DE SIMULACIÓN - TOP_FT245 (Modo Ráfaga)
# Autor: Francisco Jesús Martín Lastre
# ==============================================================================

# 1. Preparación del entorno
restart
catch { remove_wave [get_waves *] }

# Señales principales del TOP
add_wave clk
add_wave reset
add_wave FT245_TXEn
add_wave -color magenta FT245_WRn
add_wave -color orange FT245_D

# Señales internas útiles para ver el comportamiento
add_wave -color cyan /TOP_FT245/user_ready
add_wave -color yellow /TOP_FT245/counter
add_wave -color pink /TOP_FT245/FT245_inst/state_reg
add_wave user_wren

# Reloj 100 MHz (Periodo 10ns)
add_force clk {1 0ns} {0 5ns} -repeat_every 10ns

# ==============================================================================
# 2. Inicialización y Reset
# ==============================================================================
add_force reset 1
# El PC arranca indicando que NO está listo para recibir
add_force FT245_TXEn 1
run 5ns

# Liberamos el reset en t=30ns
add_force reset 0
run 10ns

# ==============================================================================
# 3. Transmisión en Ráfaga Continua
# ==============================================================================
# El PC (chip UM232H) baja la señal indicando que tiene espacio libre
add_force FT245_TXEn 0
run 40ns
add_force FT245_TXEn 1
run 20ns
add_force FT245_TXEn 0
run 10ns
add_force FT245_TXEn 1
run 20ns
add_force FT245_TXEn 0
run 10ns