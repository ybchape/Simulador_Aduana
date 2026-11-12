extends Control

# Ruta a la escena principal 
@export_file("*.tscn") var primera_escena_path: String = "res://escenas/tutorial/tutorial.tscn"
@export_file("*.tscn") var controles_escena_path: String = "res://escenas/tutorial/controles.tscn"
@export_file("*.tscn") var menu_principal_path: String = "res://escenas/menu_principal.tscn"
# Busca el botón automáticamente 
@onready var boton_jugar: Button = find_child("ButtonPlay", true, false)
@onready var boton_controles: Button = find_child("ButtonControles", true, false)
#
@onready var boton_salir: Button = find_child("ButtonSalir", true, false) 

func _ready() -> void:
	if boton_jugar and not boton_jugar.is_connected("pressed", _on_boton_jugar_pressed):
		boton_jugar.pressed.connect(_on_boton_jugar_pressed)
		
	if boton_controles and not boton_controles.is_connected("pressed", _on_button_controles_pressed):
		boton_controles.pressed.connect(_on_button_controles_pressed)
		
	if boton_salir and not boton_salir.is_connected("pressed", _on_button_salir_pressed):
		boton_salir.pressed.connect(_on_button_salir_pressed)
	# Conectamos la señal pressed click izq
	#if boton_jugar:
		#boton_jugar.pressed.connect(_on_boton_jugar_pressed)
	#else:
		#print("No se encontró el botón ButtonPlay.")

func _on_boton_jugar_pressed() -> void:
	AudioManager.reproducir_click_menu()
	# cambia a la música de gameplay
	AudioManager.reproducir_musica_gameplay()

	# transición fluida al gameplay
	if primera_escena_path != "":
		var resultado = get_tree().change_scene_to_file(primera_escena_path)
		print("Resultado del cambio de escena (0 es ok): ", resultado)
	else:
		print("No seconfiguro la ruta a la escena principal.")

func _on_button_controles_pressed() -> void:
	AudioManager.reproducir_click_menu()
	if controles_escena_path != "":
		var resultado = get_tree().change_scene_to_file(controles_escena_path)
		print("Resultado del cambio de escena a Controles (0 es ok): ", resultado)
	else:
		print("No se configuró la ruta a la escena controles.")

func _on_button_salir_pressed() -> void:
	AudioManager.reproducir_click_menu()
	get_tree().quit()

func _on_boton_volver_pressed() -> void:
	AudioManager.reproducir_click_menu()
	if menu_principal_path != "":
		var resultado = get_tree().change_scene_to_file(menu_principal_path)
		print("Resultado del cambio al menú principal (0 es ok): ", resultado)
	else:
		print("No se configuró la ruta al menú principal.")
