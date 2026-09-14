extends Control

@onready var modelo_3d = $SubViewportContainer/SubViewport/MeshInstance3D

# Creamos una variable para saber si estamos viendo la pantalla o no
var estamos_viendo_pantalla = false

func _ready():
	# Nos conectamos al megáfono del Bus de Eventos
	EventBus.escanear_objeto.connect(_mostrar_en_pantalla)

func _mostrar_en_pantalla(forma_recibida):
	# 1. Ponemos la forma 3D en la pantalla
	modelo_3d.mesh = forma_recibida
	
	# 2. Hacemos que la pantalla se vuelva VISIBLE
	show()
	
	# 3. Le pedimos a Godot que espere un cuartito de segundo. 
	# Esto es un truco para que el MISMO clic que usaste para escanear, 
	# no cierre la pantalla por accidente de forma instantánea.
	await get_tree().create_timer(1).timeout
	
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
