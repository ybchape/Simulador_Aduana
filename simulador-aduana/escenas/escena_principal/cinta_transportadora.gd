class_name CintaTransportadora
extends Node3D

@export var velocidad: float = 2.0
@export var velocidad_animacion_cinta: float = 0.5

@export var material_cinta: StandardMaterial3D
# Puntos del recorrido de ENTRADA (desde la persiana hasta la zona de inspección)
@export var ruta_entrada: Array[Marker3D] = []

# Puntos del recorrido de SALIDA PERMITIDO (desde la inspección hacia la salida)
@export var punto_salida_final: Marker3D 
#var par guardar las veloc base cuando finaliza la alta demanda
@export var velocidad_base: float = 2.0
# Segundos máximos antes de penalizar por acumulación
@export var limite_tiempo_espera: float = 8.0 
var velocidad_animacion_base: float = 0.5

var caja_actual: Node3D = null
var estado: String = "ESPERANDO" # ESPERANDO, AVANZANDO, INSPECCIONANDO, SALIENDO, DETENIDO
var indice_punto_actual: int = 0
var jornada_completada: bool = false
var notificada_inspeccion: bool = false
#var para control de alta demanda
var tiempo_acumulado_espera : float = 0.0

func _ready() -> void:
	# save veloc base al iniciar
	velocidad_base = velocidad
	velocidad_animacion_base = velocidad_animacion_cinta
	EventBus.decision_tomada.connect(_on_decision_tomada)
	EventBus.objetivo_dia_alcanzado.connect(_on_objetivo_alcanzado)

	#concexiones evento alta demanda
	EventBus.evento_alta_demanda_iniciado.connect(_on_alta_demanda_iniciado)
	EventBus.evento_alta_demanda_finalizado.connect(_on_alta_demanda_finalizado)
	

func _process(delta: float) -> void:
	if jornada_completada:
		return

# Control de acumulación / demora durante la inspección de alta demanda
	var gestor_eventos = get_node_or_null("res://escenas/escena_principal/gestor_eventos.gd") 
	if estado == "INSPECCIONANDO":
		# Si el GameManager sabe que estamos en alta demanda + tiempo de demora
		if GameManager and GameManager.esta_en_alta_demanda:
			tiempo_acumulado_espera += delta
			if tiempo_acumulado_espera >= limite_tiempo_espera:
				GameManager.registrar_acumulacion_excesiva()
				tiempo_acumulado_espera = 0.0 # Reiniciamos para evitar penalización por cada frame
	else:
		tiempo_acumulado_espera = 0.0

	# ANIMACIÓN VISUAL: Desplazamos la textura solo cuando la caja se mueve
	if estado in ["AVANZANDO", "SALIENDO"] and material_cinta != null:
		material_cinta.uv1_offset.x += delta * velocidad_animacion_cinta

	if caja_actual == null:
		return

	match estado:
		"AVANZANDO":
			_mover_entrada(delta)

		"SALIENDO":
			_mover_salida(delta)

func _mover_entrada(delta: float) -> void:
	if ruta_entrada.is_empty() or indice_punto_actual >= ruta_entrada.size():
		return

	var objetivo: Vector3 = ruta_entrada[indice_punto_actual].global_position
	caja_actual.global_position = caja_actual.global_position.move_toward(objetivo, velocidad * delta)

	if caja_actual.global_position.distance_to(objetivo) < 0.1:
		indice_punto_actual += 1
		
		# Solo habilita botones y herramientas al llegar al último marcador y detenerse.
		if indice_punto_actual >= ruta_entrada.size():
			estado = "INSPECCIONANDO"
			_notificar_inicio_inspeccion()

func _notificar_inicio_inspeccion() -> void:
	if not notificada_inspeccion:
		notificada_inspeccion = true
		EventBus.pedido_en_zona.emit(true)

# ==========================================
# NUEVO: Función para mover la caja hacia la salida
# ==========================================
func _mover_salida(delta: float) -> void:
	if punto_salida_final == null:
		return

	var objetivo: Vector3 = punto_salida_final.global_position
	caja_actual.global_position = caja_actual.global_position.move_toward(objetivo, velocidad * delta)

	# Cuando llega al punto de salida final, se destruye la caja y se libera la variable
	if caja_actual.global_position.distance_to(objetivo) < 0.1:
		estado = "ESPERANDO"
		notificada_inspeccion = false
		EventBus.pedido_en_zona.emit(false)
		if is_instance_valid(caja_actual):
			caja_actual.queue_free()
		caja_actual = null
		
		# Aquí dispararemos el siguiente pedido automáticamente
		EventBus.emit_signal("siguiente_pedido_solicitado")

func registrar_caja(nueva_caja: Node3D) -> void:
	notificada_inspeccion = false
	EventBus.pedido_en_zona.emit(false)
	if nueva_caja == null or ruta_entrada.is_empty():
		print("Error: Falta la caja o la ruta de entrada está vacía.")
		return

	caja_actual = nueva_caja
	indice_punto_actual = 0
	# se teletransporta al primer punto (Persiana)
	caja_actual.global_position = ruta_entrada[0].global_position
	estado = "AVANZANDO"

func _on_decision_tomada(_fue_permitido: bool) -> void:
	if estado == "INSPECCIONANDO" and caja_actual != null:
		# MODIFICADO: Ahora, sin importar si se permite o deniega, pasa a estado SALIENDO
		estado = "SALIENDO"

func _on_objetivo_alcanzado(_stats: Dictionary = {}) -> void:
	jornada_completada = true
	estado = "DETENIDO"

func _on_alta_demanda_iniciado(_duracion:float) -> void:
		print ("Acelareción de la cinta: ALTA DEMANDA")
		# multiplicamos por 1.8 para que la cinta corra mas rapido (ajustar veloc)
		velocidad = velocidad_base * 2.3
		velocidad_animacion_cinta = velocidad_animacion_base * 2.3

func _on_alta_demanda_finalizado() -> void:
		print ("Alta demanda FINALIZADA. Velocidad de la cinta normal.")
		velocidad = velocidad_base
		velocidad_animacion_cinta = velocidad_animacion_base
