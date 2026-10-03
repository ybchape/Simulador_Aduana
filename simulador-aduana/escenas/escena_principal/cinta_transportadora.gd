class_name CintaTransportadora
extends Node3D

@export var velocidad: float = 2.0
@export var punto_entrada: Marker3D
@export var punto_inspeccion: Marker3D
@export var punto_salida_permitido: Marker3D

var caja_actual: Node3D = null
var estado: String = "ESPERANDO" # ESPERANDO, AVANZANDO, INSPECCIONANDO, SALIENDO, DETENIDO
var jornada_completada: bool = false

func _ready() -> void:
	EventBus.pedido_en_zona.connect(_on_pedido_en_zona)
	EventBus.decision_tomada.connect(_on_decision_tomada)
	EventBus.objetivo_dia_alcanzado.connect(_on_objetivo_alcanzado)

func _process(delta: float) -> void:
	if jornada_completada or caja_actual == null:
		return

	match estado:
		"AVANZANDO":
			# Mueve la caja suavemente hacia el centro de la cinta
			caja_actual.global_position = caja_actual.global_position.move_toward(
				punto_inspeccion.global_position, velocidad * delta
			)

		"SALIENDO":
			# Mueve la caja hacia el final de la cinta a la derecha
			caja_actual.global_position = caja_actual.global_position.move_toward(
				punto_salida_permitido.global_position, velocidad * delta
			)
			# Al llegar al final de la cinta, se libera
			if caja_actual.global_position.distance_to(punto_salida_permitido.global_position) < 0.1:
				estado = "ESPERANDO"
				caja_actual.queue_free()
				caja_actual = null

func registrar_caja(nueva_caja: Node3D) -> void:
	caja_actual = nueva_caja
	caja_actual.global_position = punto_entrada.global_position
	estado = "AVANZANDO"

func _on_pedido_en_zona(hay_pedido: bool) -> void:
	if hay_pedido and estado == "AVANZANDO":
		# Se frena justo frente al jugador cuando entra al Area3D
		estado = "INSPECCIONANDO"

func _on_decision_tomada(fue_permitido: bool) -> void:
	if estado == "INSPECCIONANDO" and caja_actual != null:
		if fue_permitido:
			# Si se aprueba, avanza por la cinta
			estado = "SALIENDO"
		else:
			# Si se deniega, la cinta suelta el control y caja_interactiva.gd la destruye
			estado = "ESPERANDO"
			caja_actual = null

func _on_objetivo_alcanzado(_stats: Dictionary = {}) -> void:
	jornada_completada = true
	estado = "DETENIDO"
