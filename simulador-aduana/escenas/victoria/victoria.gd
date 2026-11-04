extends Control
@onready var menu_button: Button = $Fondo/VBoxContainer/TituloGanaste/VolverMenu

func _ready() -> void:

	menu_button.pressed.connect(_on_menu_pressed)
	
	# Guardamos automáticamente las métricas de esta victoria en el CSV
	#Metrics.export_to_csv()


func _on_menu_pressed() -> void:
	# Cierra la sesión actual
	#Metrics.start_new_session()
	
	# Vuelve al menú principal
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")
