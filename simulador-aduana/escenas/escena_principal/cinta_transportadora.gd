class_name CintaTransportadora
extends Node3D

@export var velocidad: float = 2.0
@export var velocidad_animacion_cinta: float = 0.5

@export var material_cinta: StandardMaterial3D
# Puntos del recorrido de ENTRADA (desde la persiana hasta la zona de inspección)
@export var ruta_entrada: Array[Marker3D] = []

# Puntos del recorrido de SALIDA PERMITIDO (desde la inspección hacia la salida)
@export var punto_salida_final: Marker3D 


var caja_actual: Node3D = null
var estado: String = "ESPERANDO" # ESPERANDO, AVANZANDO, INSPECCIONANDO, SALIENDO, DETENIDO
var indice_punto_actual: int = 0
var jornada_completada: bool = false

func _ready() -> void:
	EventBus.pedido_en_zona.connect(_on_pedido_en_zona)
	EventBus.decision_tomada.connect(_on_decision_tomada)
	EventBus.objetivo_dia_alcanzado.connect(_on_objetivo_alcanzado)

func _process(delta: float) -> void:
	if jornada_completada:
		return

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
		
		# Si llegó al último punto de entrada (zona de trabajo), se frena
		if indice_punto_actual >= ruta_entrada.size():
			estado = "INSPECCIONANDO"

func _mover_salida(delta: float) -> void:
	if punto_salida_final == null:
		return

	var objetivo: Vector3 = punto_salida_final.global_position
	caja_actual.global_position = caja_actual.global_position.move_toward(objetivo, velocidad * delta)

	# Cuando toca el punto final metido en la pared derecha, se elimina
	if caja_actual.global_position.distance_to(objetivo) < 0.1:
		estado = "ESPERANDO"
		if is_instance_valid(caja_actual):
			caja_actual.queue_free()
		caja_actual = null

func registrar_caja(nueva_caja: Node3D) -> void:
	if nueva_caja == null or ruta_entrada.is_empty():
		print("Error: Falta la caja o la ruta de entrada está vacía.")
		return

	caja_actual = nueva_caja
	indice_punto_actual = 0
	# se teletransporta al primer punto (Persiana)
	caja_actual.global_position = ruta_entrada[0].global_position
	estado = "AVANZANDO"

func _on_pedido_en_zona(hay_pedido: bool) -> void:
	if hay_pedido and estado == "AVANZANDO":
		# Se frena justo frente al jugador cuando entra al Area3D
		estado = "INSPECCIONANDO"

func _on_decision_tomada(fue_permitido: bool) -> void:
	if estado == "INSPECCIONANDO" and caja_actual != null:
		if fue_permitido:
			estado = "SALIENDO"
		else:
			estado = "ESPERANDO"
			caja_actual = null

func _on_objetivo_alcanzado(_stats: Dictionary = {}) -> void:
	jornada_completada = true
	estado = "DETENIDO"
