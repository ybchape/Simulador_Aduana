extends Node

signal dinero_cambiado(nuevo_saldo: int)

# signals para la gestión de errores y fin de juego 
signal error_registrado(total_errores: int)
signal game_over

var dia_actual: int = 1
# la billetera empieza vacía y es la fuente única de plata
var dinero_total: int = 0
var pedidos_realizados_hoy: int = 0
var mejoras_compradas: Array[String] = []

# var para penalizaciones y estadísticas del día 
var errores_hoy: int = 0
const MAX_ERRORES: int = 3
const PENALIZACION_ERROR: int = 20

var dinero_ganado_hoy: int = 0
var dinero_descontado_hoy: int = 0
var pedidos_correctos_hoy: int = 0

# Cantidad de pedidos por día laboral.
const OBJETIVOS_POR_DIA: Dictionary = {
	1: 3,
	2: 6,
	3: 10,
	4: 15,
}

func obtener_objetivo_actual() -> int:
	return OBJETIVOS_POR_DIA.get(dia_actual, 15)

func avanzar_siguiente_dia() -> void:
	dia_actual += 1
	pedidos_realizados_hoy = 0
	# El saldo y las compras se conservan entre días.

	# Reiniciar contadores diarios al pasar de día 
	errores_hoy = 0
	dinero_ganado_hoy = 0
	dinero_descontado_hoy = 0
	pedidos_correctos_hoy = 0

func gastar_dinero(cantidad: int) -> bool:
	if cantidad <= 0 or dinero_total < cantidad:
		return false
	dinero_total -= cantidad
	dinero_cambiado.emit(dinero_total)
	return true

func acumular_dinero(cantidad: float) -> void:
	# Acepta ganancias positivas y balances netos negativos.
	dinero_total += int(cantidad)
	dinero_cambiado.emit(dinero_total)
	print("Dinero total acumulado: $", dinero_total)

func registrar_mejora(id: String) -> void:
	if not mejoras_compradas.has(id):
		mejoras_compradas.append(id)

# Métodos para evaluar decisiones de paquetes y penalizaciones 
# Llama a esto cuando el jugador aprueba un paquete
func procesar_aprobar_paquete(es_ilegal: bool) -> void:
	pedidos_realizados_hoy += 1
	if es_ilegal:
		# Aprobar paquete con objetos ilegales descuenta $30
		_aplicar_error("Aprobó un paquete ilegal")
	else:
		_registrar_acierto(50) # Recompensa por pedido correcto

# Llama a esto cuando el jugador deniega un paquete
func procesar_denegar_paquete(es_ilegal: bool) -> void:
	pedidos_realizados_hoy += 1
	if not es_ilegal:
		# Denegar un paquete correcto descuenta $30
		_aplicar_error("Denegó un paquete correcto")
	else:
		_registrar_acierto(50) # Recompensa por rechazo correcto

func _aplicar_error(motivo: String) -> void:
	errores_hoy += 1
	dinero_descontado_hoy += PENALIZACION_ERROR
	dinero_total -= PENALIZACION_ERROR
	
	dinero_cambiado.emit(dinero_total)
	error_registrado.emit(errores_hoy)
	print("Error: ", motivo, " | Descuento: -$", PENALIZACION_ERROR)
	
	if errores_hoy >= MAX_ERRORES:
		game_over.emit()
		print("Game Over: Se alcanzaron los 3 errores permitidos.")

func _registrar_acierto(recompensa: int) -> void:
	pedidos_correctos_hoy += 1
	dinero_ganado_hoy += recompensa
	dinero_total += recompensa
	dinero_cambiado.emit(dinero_total)

# Retorna la estructura de datos que requiere la ventana de resumen
func obtener_stats_resumen() -> Dictionary:
	return {
		"correctos": pedidos_correctos_hoy,
		"total": pedidos_realizados_hoy,
		"ganado": dinero_ganado_hoy,
		"descontado": dinero_descontado_hoy,
		"neto": dinero_ganado_hoy - dinero_descontado_hoy
	}
