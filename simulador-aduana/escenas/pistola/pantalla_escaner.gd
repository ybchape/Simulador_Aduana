extends Control

@onready var modelo_3d: MeshInstance3D = $SubViewportContainer/SubViewport/MeshInstance3D
@onready var camera_3d: Camera3D = $SubViewportContainer/SubViewport/Camera3D

var estamos_viendo_pantalla: bool = false
var esta_cansado: bool = false
var request_id: int = 0

func _ready() -> void:
	EventBus.escanear_objeto.connect(_mostrar_en_pantalla)
	EventBus.evento_cansancio_iniciado.connect(_al_iniciar_cansancio)
	EventBus.evento_cansancio_finalizado.connect(_al_finalizar_cansancio)
	if camera_3d:
		camera_3d.fov = 30.0
	mouse_filter = Control.MOUSE_FILTER_STOP

func _al_iniciar_cansancio(_duracion: float) -> void:
	esta_cansado = true

func _al_finalizar_cansancio() -> void:
	esta_cansado = false
		
func _mostrar_en_pantalla(forma_recibida: Mesh) -> void:
	if not forma_recibida or not modelo_3d:
		return
	request_id += 1
	var id_solicitud: int = request_id
	
	# 1. Ponemos la forma 3D en la pantalla
	modelo_3d.mesh = forma_recibida
	
	# AUTO-ENCUADRE Y ZOOM 
	# Centra el objeto según su centro geométrico verdadero
	var aabb = forma_recibida.get_aabb()
	
	if aabb.size.length() > 0:
		# Centra la geometría en la coordenada local origen
		modelo_3d.position = -aabb.get_center()
		
		# Calcula el tamaño máximo para normalizar la escala
		var tamano_maximo = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		if tamano_maximo > 0:
			# Un factor de 0.85 a 0.90 evita que los bordes del objeto queden cortados
			var factor_escala = 0.9 / tamano_maximo
			modelo_3d.scale = Vector3(factor_escala, factor_escala, factor_escala)
	
	# 2. Hacemos que la pantalla se vuelva VISIBLE
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	#  Lentitud POR CANSANCIO EXTREMO 
	# Si está cansado tarda 3.0s, si no, 1.0s normal
	var tiempo_espera: float = 3.0 if esta_cansado else 1.0
	await get_tree().create_timer(tiempo_espera).timeout
	if not is_inside_tree() or not visible or request_id != id_solicitud:
		return

	# La pantalla ya puede recibir el clic que la cierra.
	estamos_viendo_pantalla = true

func ocultar() -> void:
	estamos_viendo_pantalla = false
	request_id += 1
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if estamos_viendo_pantalla and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		ocultar()
		get_viewport().set_input_as_handled()
