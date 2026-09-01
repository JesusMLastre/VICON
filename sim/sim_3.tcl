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


add_wave TXEn
add_wave -color yellow /FT245_IF/TXEn_sync
add_wave -color magenta WRn
add_wave -color lightpurple DATA
add_wave -color orange DIN
add_wave -color pink /FT245_IF/state_reg

# Reloj 100 MHz (Periodo 10ns: sube en 0, 10, 20... baja en 5, 15, 25...)
add_force clk {1 0ns} {0 5ns} -repeat_every 10ns

# ==========================================
# 2. Inicialización (t = 0 ns)
# ==========================================
add_force reset 1
add_force wr_en 0
add_force TXEn 1
add_force DIN -radix hex 00
run 15ns

# ==========================================
# 3. Preparación (t = 15 ns, flanco de bajada)
# ==========================================
add_force reset 0
add_force wr_en 1
add_force DIN -radix hex F1
run 10ns

# ==========================================
# 4. Primer ciclo de escritura
# ==========================================
# t = 25 ns (flanco bajada): La FIFO indica que hay hueco.
add_force TXEn 0
run 30ns

# t = 55 ns (flanco bajada): La FPGA bajó WRn en el flanco de subida de 50 ns.
# El esclavo reacciona subiendo TXEn (simulamos un T6 de 5 ns).
add_force TXEn 1
run 80ns

# ==========================================
# 5. Segundo ciclo de escritura
# ==========================================
# t = 135 ns (flanco bajada): Preparamos el siguiente dato.
add_force DIN -radix hex F2
run 10ns

# t = 145 ns (flanco bajada): La FPGA subió WRn en t = 90 ns.
# Han pasado 55 ns. Respetamos el T7 mínimo de 49 ns antes de bajar TXEn.
add_force TXEn 0
run 30ns

# t = 175 ns (flanco bajada): La FPGA bajó WRn en t = 170 ns.
# El esclavo reacciona subiendo TXEn tras el tiempo T6.
add_force TXEn 1
run 50ns