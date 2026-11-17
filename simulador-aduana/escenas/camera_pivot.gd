extends Node3D

# Configuracion de sensibilidad y limites de cámara
@export_group("Sensibilidad y Límites")
@export var mouse_sensitivity: float = 0.002

# Rangos de visión (en grados)
@export var min_yaw_deg: float = -40.0   # Límite izquierda
@export var max_yaw_deg: float = 40.0    # Límite derecha
@export var min_pitch_deg: float = -25.0 # Límite abajo (mirar cinta/mesa)
@export var max_pitch_deg: float = 20.0  # Límite arriba (mirar pared)

# --- CONFIGURACIÓN DE ZOOM ---
@export_group("Configuración Zoom")
@export var fov_normal: float = 75.0     # FOV por defecto (vista lejana)
@export var fov_zoom: float = 40.0       # FOV máximo de zoom (vista cercana)
@export var velocidad_zoom: float = 5.0  # Sensibilidad del scroll
@export var suavizado_zoom: float = 12.0 # Velocidad de transición suave

# --- CONFIGURACIÓN DE CANSANCIO (PESADEZ) ---
@export_group("Efecto Cansancio")
@export var factor_sensibilidad_cansado: float = 0.18 # Antes 0.35 (mucho más lento)
@export var inercia_camara_normal: float = 25.0       # Respuesta casi instantánea normal
@export var inercia_camara_cansado: float = 3.2       # Arrastrado y pesado al estar cansado
@export var factor_velocidad_zoom_cansado: float = 0.4 # La ruedita responde menos
@export var suavizado_zoom_cansado: float = 2.5       # El lente tarda en enfocar

@onready var camera: Camera3D = $Camera3D

# Ámbitos de rotación en radianes
var pitch: float = 0.0 # Eje X (Arriba / Abajo)
var yaw: float = 0.0   # Eje Y (Izquierda / Derecha)
var pitch_objetivo: float = 0.0
var yaw_objetivo: float = 0.0

# Estado para saber si estamos arrastrando la vista
var is_rotating: bool = false

# Variable de control del zoom
var fov_objetivo: float = 75.0

# --- VARIABLE Y CONEXIÓN DE CANSANCIO ---
var esta_cansado: bool = false
var _tiempo_cansancio: float = 0.0

func _ready() -> void:
# El cursor inicia visible para poder interactuar libremente
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	camera.transform = Transform3D.IDENTITY
# Espera a que el jugador confirme el cartel para empezar la pesadez (igual que el gestor)
	if EventBus.has_signal("cansancio_confirmado"):
		EventBus.cansancio_confirmado.connect(func(): esta_cansado = true)
	else:
		EventBus.evento_cansancio_iniciado.connect(func(_duracion): esta_cansado = true)
		
	EventBus.evento_cansancio_finalizado.connect(func(): 
		esta_cansado = false
		_tiempo_cansancio = 0.0
	)

func _process(delta: float) -> void:
	# ZOOM PESADO
	var suavizado_fov_actual: float = suavizado_zoom_cansado if esta_cansado else suavizado_zoom

	# Interpola el FOV suavemente hacia el objetivo en cada fotograma
	if camera:
		camera.fov = lerp(camera.fov, fov_objetivo, suavizado_zoom * delta)

# CÁMARA CON INERCIA (Arrastre pesado)
	var inercia_actual: float = inercia_camara_cansado if esta_cansado else inercia_camara_normal
	yaw = lerpf(yaw, yaw_objetivo, inercia_actual * delta)
	pitch = lerpf(pitch, pitch_objetivo, inercia_actual * delta)

	# CABECEO DE CANSANCIO (Se le cae un poco la cabeza y ladea levemente)
	var cabeceo_pitch: float = 0.0
	var balanceo_roll: float = 0.0
	if esta_cansado:
		_tiempo_cansancio += delta
		# Oscilación lenta que simula que le pesa la cabeza
		cabeceo_pitch = sin(_tiempo_cansancio * 1.4) * deg_to_rad(1.8) - deg_to_rad(1.5)
		balanceo_roll = cos(_tiempo_cansancio * 0.9) * deg_to_rad(1.5)

	rotation = Vector3(pitch + cabeceo_pitch, yaw, balanceo_roll)

func _unhandled_input(event: InputEvent) -> void:
# --- CONTROL DE ZOOM CON RUEDITA DEL MOUSE ---
	if event is InputEventMouseButton and event.pressed:
		var vel_zoom_actual: float = velocidad_zoom * (factor_velocidad_zoom_cansado if esta_cansado else 1.0)
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			fov_objetivo = clampf(fov_objetivo - vel_zoom_actual, fov_zoom, fov_normal)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			fov_objetivo = clampf(fov_objetivo + vel_zoom_actual, fov_zoom, fov_normal)
	
	# Detecta cuando se presiona o suelta el Clic Derecho
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			is_rotating = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			is_rotating = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Actualiza el OBJETIVO de rotación (el movimiento real ocurre con inercia en _process)
	if event is InputEventMouseMotion and is_rotating:
		var factor_velocidad: float = factor_sensibilidad_cansado if esta_cansado else 1.0
		var sensibilidad_actual = mouse_sensitivity * factor_velocidad

		yaw_objetivo -= event.relative.x * sensibilidad_actual
		pitch_objetivo -= event.relative.y * sensibilidad_actual

		yaw_objetivo = clamp(yaw_objetivo, deg_to_rad(min_yaw_deg), deg_to_rad(max_yaw_deg))
		pitch_objetivo = clamp(pitch_objetivo, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
