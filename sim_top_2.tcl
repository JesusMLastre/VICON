# ==============================================================================
# SCRIPT DE SIMULACIÓN - TOP_FT245_Test (Modo Ráfaga)
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
add_wave -color orange -radix hex FT245_D

# Señales internas útiles para ver el comportamiento
add_wave -color cyan /TOP_FT245_Test/user_ready
add_wave -color yellow -radix hex /TOP_FT245_Test/counter
add_wave -color pink /TOP_FT245_Test/FT245_inst/state_reg
add_wave user_wren

# Reloj 100 MHz (Periodo 10ns: sube en 0, 10, 20... baja en 5, 15, 25...)
add_force clk {1 0ns} {0 5ns} -repeat_every 10ns

# ==============================================================================
# 2. Inicialización y Reset (t = 0 ns)
# ==============================================================================
add_force reset 1
# El chip arranca indicando que NO está listo para recibir
add_force FT245_TXEn 1
add_force user_wren 1
run 15ns

# ==============================================================================
# 3. Liberación de Reset (t = 15 ns, flanco de bajada)
# ==============================================================================
add_force reset 0
run 10ns

# ==============================================================================
# 4. Primer ciclo de escritura
# ==============================================================================
# t = 25 ns (bajada): El chip FT245 baja TXEn indicando espacio libre.
add_force FT245_TXEn 0
run 40ns

# t = 65 ns (bajada): La FPGA acaba de poner WRn a '0' en t = 60 ns.
# Simulamos el tiempo de reacción T6 del esclavo (aprox 5 ns) subiendo TXEn.
add_force FT245_TXEn 1

#add_force user_wren 0
#run 90ns
run 50ns
# ==============================================================================
# 5. Segundo ciclo de escritura
# ==============================================================================
# t = 155 ns (bajada): La FPGA subió WRn en t = 100 ns.
# Han pasado 55 ns, respetando el tiempo T7 (mínimo 49 ns). Volvemos a bajar TXEn.
add_force FT245_TXEn 0
run 40ns

# t = 195 ns (bajada): La FPGA puso WRn a '0' en t = 190 ns.
# El esclavo reacciona de nuevo tras el tiempo T6.
add_force FT245_TXEn 1
run 50ns
# ==============================================================================
# 6. Tercer ciclo de escritura
# ==============================================================================
add_force FT245_TXEn 0
run 40ns

add_force FT245_TXEn 1
run 50ns