extends Control

# Ruta a la escena principal 
@export_file("*.tscn") var primera_escena_path: String = "res://escenas/escena_principal/escena_principal.tscn"

@onready var boton_jugar: Button = $Fondo/VBoxContainer/TituloJuego/ButtonPlay

func _ready() -> void:
	# Conectamos la señal pressed click izq
	if boton_jugar:
		boton_jugar.pressed.connect(_on_boton_jugar_pressed)
	else:
		print("No se encontró el botón ButtonPlay.")

func _on_boton_jugar_pressed() -> void:
	# transición fluida al gameplay
	if primera_escena_path != "":
		get_tree().change_scene_to_file(primera_escena_path)
	else:
		print("No seconfiguro la ruta a la escena principal.")
