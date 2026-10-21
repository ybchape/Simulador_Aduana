extends Control

@onready var modelo_3d = $SubViewportContainer/SubViewport/MeshInstance3D
@onready var camera_3d: Camera3D = $SubViewportContainer/SubViewport/Camera3D 

# Creamos una variable para saber si estamos viendo la pantalla o no
var estamos_viendo_pantalla = false

# Estado local del cansancio recibido mediante EventBus
var esta_cansado: bool = false

func _ready():
	# Nos conectamos al megáfono del Bus de Eventos
	EventBus.escanear_objeto.connect(_mostrar_en_pantalla)

# Conecta las señales para actualizar la variable esta_cansado automáticamente
	EventBus.evento_cansancio_iniciado.connect(func(_duracion): esta_cansado = true)
	EventBus.evento_cansancio_finalizado.connect(func(): esta_cansado = false)


# Ajusta el ángulo de visión de la cámara para acercar el objeto
	if camera_3d:
		camera_3d.fov = 30.0
		
func _mostrar_en_pantalla(forma_recibida: Mesh) -> void:
	if not forma_recibida or not modelo_3d:
		return
	
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
	
	#  Lentitud POR CANSANCIO EXTREMO 
	# Si está cansado tarda 3.0s, si no, 1.0s normal
	var tiempo_espera: float = 3.0 if esta_cansado else 1.0
	await get_tree().create_timer(tiempo_espera).timeout
	

	# 4. Le avisamos al juego que ahora sí, la pantalla está activa
	estamos_viendo_pantalla = true

# Esta función de Godot escucha TODO lo que haces (teclas, clics, etc.)
func _input(event):
	# Preguntamos: ¿La pantalla está activa Y además tocaste un botón del mouse?
	if estamos_viendo_pantalla and event is InputEventMouseButton:
		
		# Preguntamos: ¿Fue el botón izquierdo y lo acabas de presionar?
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			
			# 1. Escondemos la pantalla
			hide()
			
			# 2. Le avisamos al juego que ya no estamos viendo la pantalla
			estamos_viendo_pantalla = false
