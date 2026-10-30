extends Control

# Ruta a la escena principal 
@export_file("*.tscn") var primera_escena_path: String = "res://escenas/tutorial/tutorial.tscn"

# Busca el botón automáticamente 
@onready var boton_jugar: Button = find_child("ButtonPlay", true, false)

func _ready() -> void:
	# Conectamos la señal pressed click izq
	if boton_jugar:
		boton_jugar.pressed.connect(_on_boton_jugar_pressed)
	else:
		print("No se encontró el botón ButtonPlay.")

func _on_boton_jugar_pressed() -> void:
	# transición fluida al gameplay
	if primera_escena_path != "":
		var resultado = get_tree().change_scene_to_file(primera_escena_path)
		print("Resultado del cambio de escena (0 es ok): ", resultado)
	else:
		print("No seconfiguro la ruta a la escena principal.")
