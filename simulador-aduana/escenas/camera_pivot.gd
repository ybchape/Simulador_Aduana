extends Node3D

# Configuracion de sensibilidad y limites de cámara
@export_group("Sensibilidad y Límites")
@export var mouse_sensitivity: float = 0.002

# Rangos de visión (en grados)
@export var min_yaw_deg: float = -40.0   # Límite izquierda
@export var max_yaw_deg: float = 40.0    # Límite derecha
@export var min_pitch_deg: float = -25.0 # Límite abajo (mirar cinta/mesa)
@export var max_pitch_deg: float = 20.0  # Límite arriba (mirar pared)

@onready var camera: Camera3D = $Camera3D

# Ámbitos de rotación en radianes
var pitch: float = 0.0 # Eje X (Arriba / Abajo)
var yaw: float = 0.0   # Eje Y (Izquierda / Derecha)

# Estado para saber si estamos arrastrando la vista
var is_rotating: bool = false

# --- VARIABLE Y CONEXIÓN DE CANSANCIO ---
var esta_cansado: bool = false


func _ready() -> void:
# El cursor inicia visible para poder interactuar libremente
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	camera.transform = Transform3D.IDENTITY

# Escucha los eventos de cansancio del EventBus para actualizar la variable local
	EventBus.evento_cansancio_iniciado.connect(func(_duracion): esta_cansado = true)
	EventBus.evento_cansancio_finalizado.connect(func(): esta_cansado = false)

func _unhandled_input(event: InputEvent) -> void:
	# Detecta cuando se presiona o suelta el Clic Derecho (MOUSE_BUTTON_RIGHT)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			is_rotating = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Oculta y fija el cursor mientras rotás
		else:
			is_rotating = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # Libera el cursor al soltar

	# Rota la cámara ÚNICAMENTE si se está manteniendo presionado el clic derecho
	if event is InputEventMouseMotion and is_rotating:
		# Factor de lentitud por cansancio
		var factor_velocidad: float = 0.35 if esta_cansado else 1.0
		var sensibilidad_actual = mouse_sensitivity * factor_velocidad

		yaw -= event.relative.x * sensibilidad_actual
		pitch -= event.relative.y * sensibilidad_actual

		# ángulos según los límites establecidos
		yaw = clamp(yaw, deg_to_rad(min_yaw_deg), deg_to_rad(max_yaw_deg))
		pitch = clamp(pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))

		# Aplica rotación sin mover la posición 3D
		rotation = Vector3(pitch, yaw, 0.0)
