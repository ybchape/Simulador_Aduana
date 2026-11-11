class_name CintaTransportadora
extends Node3D

@export var velocidad: float = 2.0
@export var velocidad_animacion_cinta: float = 0.5

@export var material_cinta: StandardMaterial3D
# Puntos del recorrido de ENTRADA (desde la persiana hasta la zona de inspección)
# NUEVO: Ahora el último punto es la zona de inspección y los anteriores forman la cola de espera.
@export var ruta_entrada: Array[Marker3D] = []
# NUEVO: Puestos de la cola de espera (desde la zona de inspección hacia atrás)
@export var puestos_cola: Array[Marker3D] = []

# Puntos del recorrido de SALIDA PERMITIDO (desde la inspección hacia la salida)
@export var punto_salida_final: Marker3D 
@export var escena_caja: PackedScene
#var par guardar las veloc base cuando finaliza la alta demanda
@export var velocidad_base: float = 2.0
var velocidad_animacion_base: float = 0.5

# NUEVO: Cola de cajas activas en la cinta (soporta múltiples cajas en los Marker3D)
var cola_cajas: Array[Node3D] = []

# Mantenemos compatibilidad por si otros scripts leen 'caja_actual' (será siempre la primera de la fila)
var caja_actual: Node3D = null :
	get:
		return cola_cajas[0] if not cola_cajas.is_empty() else null

var estado: String = "ESPERANDO" # ESPERANDO, INSPECCIONANDO, SALIENDO, DETENIDO
var jornada_completada: bool = false
var notificada_inspeccion: bool = false
var indice_punto_actual: int = 0
var caja_waypoint_indices: Array[int] = []
var hay_movimiento: bool = false

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

	# Reiniciamos el indicador de movimiento en cada fotograma
	hay_movimiento = false

	# Actualizamos el movimiento de las cajas (esto activará hay_movimiento si alguna se desplaza)
	_actualizar_movimiento_cola(delta)

	# Animación visual de la cinta: SOLO gira si hay cajas moviéndose
	if hay_movimiento and material_cinta != null:
		material_cinta.uv1_offset.x += delta * velocidad_animacion_cinta


# ==========================================
# MOVIMIENTO ORDENADO CON DETECCIÓN DE MOVIMIENTO
# ==========================================
func _actualizar_movimiento_cola(delta: float) -> void:
	if cola_cajas.is_empty() or ruta_entrada.is_empty():
		return

	for i in range(cola_cajas.size()):
		var caja = cola_cajas[i]
		if not is_instance_valid(caja):
			continue
			
		var wp_idx = caja_waypoint_indices[i]
		var objetivo: Vector3

		# Definimos el objetivo según el waypoint
		if wp_idx < ruta_entrada.size():
			objetivo = ruta_entrada[wp_idx].global_position
		else:
			if i == 0:
				objetivo = ruta_entrada[-1].global_position # PuntoInspecc
			else:
				var idx_cola = min(i - 1, puestos_cola.size() - 1)
				if not puestos_cola.is_empty() and puestos_cola[idx_cola] != null:
					objetivo = puestos_cola[idx_cola].global_position
				else:
					objetivo = ruta_entrada[-1].global_position

		# Si la caja todavía está lejos del objetivo, significa que se está moviendo
		if caja.global_position.distance_to(objetivo) >= 0.1:
			hay_movimiento = true

		# Mover la caja de forma fluida hacia el objetivo actual
		caja.global_position = caja.global_position.move_toward(objetivo, velocidad * delta)

		# Si llegó al objetivo actual, avanzamos el waypoint
		if caja.global_position.distance_to(objetivo) < 0.1:
			if wp_idx < ruta_entrada.size():
				caja_waypoint_indices[i] += 1
			
			if i == 0 and wp_idx >= ruta_entrada.size() - 1:
				if estado != "INSPECCIONANDO" and estado != "SALIENDO":
					estado = "INSPECCIONANDO"
					_notificar_inicio_inspeccion()


func _notificar_inicio_inspeccion() -> void:
	if not notificada_inspeccion:
		notificada_inspeccion = true
		EventBus.pedido_en_zona.emit(true)
#cronometro del pedido 
	if GameManager.has_method("iniciar_temporizador_pedido"):
		GameManager.iniciar_temporizador_pedido()


# ==========================================
# SALIDA DE CAJA Y AVANCE AUTOMÁTICO DE LA FILA
# ==========================================
func _procesar_salida_caja_actual() -> void:
	if cola_cajas.is_empty():
		return

	var caja_a_salir = cola_cajas.pop_front()
	if not caja_waypoint_indices.is_empty():
		caja_waypoint_indices.pop_front()

	if is_instance_valid(caja_a_salir) and punto_salida_final != null:
		var tween = create_tween()
		var tiempo_salida = caja_a_salir.global_position.distance_to(punto_salida_final.global_position) / velocidad
		tween.tween_property(caja_a_salir, "global_position", punto_salida_final.global_position, tiempo_salida)
		tween.finished.connect(func():
			if is_instance_valid(caja_a_salir):
				caja_a_salir.queue_free()
		)

	notificada_inspeccion = false
	EventBus.pedido_en_zona.emit(false)
	
	if cola_cajas.is_empty():
		estado = "ESPERANDO"
	else:
		estado = "AVANZANDO"
		
	EventBus.emit_signal("siguiente_pedido_solicitado")

	# VERIFICACIÓN DE FILA: Mantenemos el total de 5 cajas en el sistema
	_verificar_y_llenar_cola()
	
func registrar_caja(nueva_caja: Node3D) -> void:
	if nueva_caja == null or ruta_entrada.is_empty():
		print("Error: Falta la caja o la ruta de entrada está vacía.")
		return

	var max_puestos = 5 # Límite total de 5 cajas
	if cola_cajas.size() < max_puestos:
		nueva_caja.global_position = ruta_entrada[0].global_position
		cola_cajas.append(nueva_caja)
		caja_waypoint_indices.append(0)
		estado = "AVANZANDO"
	else:
		print("La cinta está llena...")
		nueva_caja.queue_free()


func _on_decision_tomada(_fue_permitido: bool) -> void:
	if estado == "INSPECCIONANDO" and not cola_cajas.is_empty():
		if GameManager.has_method("registrar_tiempo_procesamiento_paquete"):
			GameManager.registrar_tiempo_procesamiento_paquete()
		
		# MODIFICADO: Despacha la caja actual y avanza la fila
		_procesar_salida_caja_actual()


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
		velocidad = velocidad_base * 2.3
		velocidad_animacion_cinta = velocidad_animacion_base * 2.3
		# Llenamos hasta las 5 cajas al comenzar el evento
		while cola_cajas.size() < 5:
			_verificar_y_llenar_cola()

# SPAWN AUTOMÁTICO PARA MANTENER LAS 5 CAJAS
# ==========================================
func _verificar_y_llenar_cola() -> void:
	var max_puestos = 5 # 1 en inspección + 4 en puestos de cola
	if cola_cajas.size() < max_puestos and escena_caja != null:
		var nueva_caja = escena_caja.instantiate() as Node3D
		if nueva_caja != null:
			get_tree().current_scene.add_child(nueva_caja)
			registrar_caja(nueva_caja)
