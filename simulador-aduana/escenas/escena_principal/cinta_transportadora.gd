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
var velocidad_animacion_base: float = 0.5

# Cola de cajas y límite máximo para la alta demanda 
var cola_cajas: Array[Node3D] = []
@export var limite_maximo_cola: int = 4
@export var punto_inspeccion: Marker3D

var jornada_completada: bool = false
var notificada_inspeccion: bool = false

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

	#  Desplaza la textura solo cuando la caja se mueve
	#  valida si hay cajas en la cola en lugar de caja_actual
	if not cola_cajas.is_empty() and material_cinta != null:
		material_cinta.uv1_offset.x += delta * velocidad_animacion_cinta

	# Reemplaza la lógica individual por el procesamiento de la cola 
	_procesar_cola_cajas(delta)

func _procesar_cola_cajas(delta: float) -> void:
	if cola_cajas.is_empty():
		return

	for i in range(cola_cajas.size()):
		var caja = cola_cajas[i]
		if not is_instance_valid(caja):
			continue

		# Si es la primera caja y ya fue notificada, se queda detenida aquí
		if i == 0 and notificada_inspeccion:
			continue

		var limite_max_marker = clamp(ruta_entrada.size() - 1 - i, 0, ruta_entrada.size() - 1)
		var waypoint_idx = caja.get_meta("waypoint_index", 0)
		
		if waypoint_idx > limite_max_marker:
			waypoint_idx = limite_max_marker

		var objetivo: Vector3 = ruta_entrada[waypoint_idx].global_position

		# Movimiento fluido hacia el waypoint actual
		if caja.global_transform.origin.distance_to(objetivo) > 0.05:
			caja.global_transform.origin = caja.global_transform.origin.move_toward(objetivo, velocidad * delta)
		else:
			if waypoint_idx < limite_max_marker:
				caja.set_meta("waypoint_index", waypoint_idx + 1)
			else:
				# Si la caja líder (i == 0) llegó al último marcador de la entrada
				if i == 0 and not notificada_inspeccion:
					# Verificamos si ya llegó al nodo exacto de PuntoInspeccion si está asignado
					if punto_inspeccion != null and caja.global_transform.origin.distance_to(punto_inspeccion.global_position) < 0.1:
						notificada_inspeccion = true
						EventBus.pedido_en_zona.emit(true)
						_cargar_planilla_caja_delantera(caja)

#Evita que la planilla se sobrescriba cada 5 seg; solo carga cuando la caja del frente llega 
func _cargar_planilla_caja_delantera(caja: Node3D) -> void:
	var script_caja = caja.get_node_or_null("caja_interactiva")
	if script_caja and "pedido_asociado" in script_caja and script_caja.pedido_asociado:
		var planilla = get_tree().get_first_node_in_group("planilla")
		if planilla and planilla.has_method("cargar_pedido"):
			planilla.cargar_pedido(script_caja.pedido_asociado)

func _mover_salida(caja_a_salir: Node3D) -> void:
	if punto_salida_final == null:
		if is_instance_valid(caja_a_salir):
			caja_a_salir.queue_free()
		return

	var objetivo: Vector3 = punto_salida_final.global_position
	var tween = create_tween()
	var distancia = caja_a_salir.global_position.distance_to(objetivo)
	var tiempo = distancia / max(velocidad, 0.1)
	
	tween.tween_property(caja_a_salir, "global_position", objetivo, tiempo)
	await tween.finished

	# Cuando llega al punto de salida final, se destruye la caja de forma segura
	if is_instance_valid(caja_a_salir):
		caja_a_salir.queue_free()

	notificada_inspeccion = false
	EventBus.pedido_en_zona.emit(false)

	# Actualiza los waypoints de las cajas restantes en la cola
	for i in range(cola_cajas.size()):
		var c = cola_cajas[i]
		if is_instance_valid(c):
			var actual_w = c.get_meta("waypoint_index", 0)
			var nuevo_limite = clamp(ruta_entrada.size() - 1 - i, 0, ruta_entrada.size() - 1)
			if actual_w < nuevo_limite:
				c.set_meta("waypoint_index", actual_w + 1)

func registrar_caja(nueva_caja: Node3D) -> void:
	if nueva_caja == null or ruta_entrada.is_empty():
		print("Error: Falta la caja o la ruta de entrada está vacía.")
		return

	# Configuramos el RigidBody3D en modo cinemático para control absoluto de su posición
	if nueva_caja is RigidBody3D:
		nueva_caja.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		nueva_caja.freeze = true

	# se mueve al primer punto 
	nueva_caja.global_position = ruta_entrada[0].global_position

	# inicia en el waypoint 1 para que empiece a avanzar de inmediato a la sgte posición
	if ruta_entrada.size() > 1:
		nueva_caja.set_meta("waypoint_index", 1)
	else:
		nueva_caja.set_meta("waypoint_index", 0)

	cola_cajas.append(nueva_caja)

	# Control de exceso de cola (max 4)
	if cola_cajas.size() > limite_maximo_cola and GameManager:
		if GameManager.has_method("registrar_acumulacion_excesiva"):
			GameManager.registrar_acumulacion_excesiva()

func _on_decision_tomada(_fue_permitido: bool) -> void:
	if not cola_cajas.is_empty():
		var caja_a_procesar = cola_cajas.pop_front() # Sale de la cola delantera
		notificada_inspeccion = false # Reset para la siguiente caja que viene atrás
		EventBus.pedido_en_zona.emit(false)

		# Mantenemos el freeze en true para que el Tween mueva la caja de forma limpia y fluida
		if caja_a_procesar is RigidBody3D:
			caja_a_procesar.freeze = true

		_mover_salida(caja_a_procesar)

func _on_objetivo_alcanzado(_stats: Dictionary = {}) -> void:
	jornada_completada = true

func _on_alta_demanda_iniciado(_duracion:float) -> void:
		print ("Acelareción de la cinta: ALTA DEMANDA")
		# multiplicamos por 1.8 para que la cinta corra mas rapido (ajustar veloc)
		velocidad = velocidad_base * 2.3
		velocidad_animacion_cinta = velocidad_animacion_base * 2.3

func _on_alta_demanda_finalizado() -> void:
		print ("Alta demanda FINALIZADA. Velocidad de la cinta normal.")
		velocidad = velocidad_base
		velocidad_animacion_cinta = velocidad_animacion_base
