extends Node

signal dinero_cambiado(nuevo_saldo: int)

# signals para la gestión de errores y fin de juego 
signal error_registrado(total_errores: int)
signal game_over

# Se emite cuando cambian los usos/estado de una herramienta (refresca la UI).
signal herramienta_estado_cambiado(id: String, restantes: int, maximo: int)

var dia_actual: int = 1
# la billetera empieza vacía y es la fuente única de plata
var dinero_total: int = 0
var pedidos_realizados_hoy: int = 0
var mejoras_compradas: Array[String] = []

# var para penalizaciones y estadísticas del día 
var errores_hoy: int = 0
const MAX_ERRORES: int = 3
const PENALIZACION_ERROR: int = 20

# --- Límites de uso de herramientas ---
# Usos permitidos por día. -1 = sin límite.
const USOS_BASE_HERRAMIENTA: Dictionary = {
	"escaner": 2,
	"cuter": 2,
	"balanza": 2,
	"energizante": -1,
}
# Cuántos usos extra aporta cada mejora de nivel 2 de la tienda.
const USOS_EXTRA_POR_MEJORA: int = 2
# Enfriamiento (segundos) tras cada uso antes de poder volver a usar la herramienta.
const COOLDOWN_HERRAMIENTA: float = 10.0

# Estado de uso de herramientas durante el día actual.
var _usos_gastados: Dictionary = {}
var _cooldown_restante: Dictionary = {}

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

func _ready() -> void:
	_reiniciar_usos_herramientas()

func _process(delta: float) -> void:
	# Avanza los enfriamientos activos; avisa solo cuando uno termina.
	for id in _cooldown_restante.keys():
		var restante: float = float(_cooldown_restante[id])
		if restante <= 0.0:
			continue
		restante = maxf(0.0, restante - delta)
		_cooldown_restante[id] = restante
		if restante <= 0.0:
			_emitir_estado_herramienta(id)

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

	# Reiniciar los usos de herramientas del nuevo día.
	_reiniciar_usos_herramientas()

# --- Gestión de uso de herramientas (límite diario + cooldown) ----------------

# Reinicia los usos del día (al arrancar el juego y al avanzar de día).
func _reiniciar_usos_herramientas() -> void:
	_usos_gastados.clear()
	# No limpiar _cooldown_restante aquí: preserva los tiempos de enfriamiento
	# restantes para que no se pierdan entre usos consecutivos.
	# Solo reiniciamos las cuentas de usos para contar desde 0 en el nuevo día.
	for id in USOS_BASE_HERRAMIENTA.keys():
		_usos_gastados[id] = 0
		# Inicializar cooldown solo si no existe (ej. primera vez al iniciar juego)
		if not _cooldown_restante.has(id):
			_cooldown_restante[id] = 0.0
	for id in USOS_BASE_HERRAMIENTA.keys():
		_emitir_estado_herramienta(id)

# Usos máximos por día (considera las mejoras de nivel 2). Devuelve -1 si es ilimitada.
func obtener_max_usos(id: String) -> int:
	if not USOS_BASE_HERRAMIENTA.has(id):
		return 0
	var maximo: int = int(USOS_BASE_HERRAMIENTA[id])
	if maximo < 0:
		return -1
	if mejoras_compradas.has(id + "_lvl2"):
		maximo += USOS_EXTRA_POR_MEJORA
	return maximo

# Usos restantes hoy. Devuelve -1 si la herramienta es ilimitada.
func obtener_usos_restantes(id: String) -> int:
	var maximo: int = obtener_max_usos(id)
	if maximo < 0:
		return -1
	var gastados: int = int(_usos_gastados.get(id, 0))
	return maxi(0, maximo - gastados)

func obtener_cooldown_restante(id: String) -> float:
	return float(_cooldown_restante.get(id, 0.0))

# ¿Se puede usar la herramienta ahora? (le quedan usos y no está enfriando)
# Nota: El cooldown aún se cuenta y se muestra en la UI, pero no bloquea el uso
# si el usuario aún tiene intentos diarios disponibles.
func herramienta_disponible(id: String) -> bool:
	if not USOS_BASE_HERRAMIENTA.has(id):
		return false
	# Si hay cooldown activo, bloquea el uso y se mostrará aviso de enfriamiento..
	# El cooldown seguirá contándose y se mostrará en la interfaz, pero no
	# impedirá que la herramienta se use si todavía le quedan intentos.
	if obtener_usos_restantes(id) > 0:
		return true
	# Si ya no le quedan usos, está bloqueado (aunque el cooldown haya terminado).
	return false

# Registra un uso efectivo: descuenta un uso (si aplica) e inicia el enfriamiento.
func consumir_uso_herramienta(id: String) -> bool:
	if not herramienta_disponible(id):
		return false
	if obtener_usos_restantes(id) > 0:
		_usos_gastados[id] = int(_usos_gastados.get(id, 0)) + 1
	_cooldown_restante[id] = COOLDOWN_HERRAMIENTA
	_emitir_estado_herramienta(id)
	return true

func _emitir_estado_herramienta(id: String) -> void:
	herramienta_estado_cambiado.emit(id, obtener_usos_restantes(id), obtener_max_usos(id))

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
		# Aprobar paquete con objetos ilegales descuenta $20
		_aplicar_error("Aprobó un paquete ilegal")
	else:
		_registrar_acierto(50) # Recompensa por pedido correcto

# Llama a esto cuando el jugador deniega un paquete
func procesar_denegar_paquete(es_ilegal: bool) -> void:
	pedidos_realizados_hoy += 1
	if not es_ilegal:
		# Denegar un paquete correcto descuenta $20
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
