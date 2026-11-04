extends Control

@onready var restart_button: Button = $Fondo/VBoxContainer/TituloPerdiste/Reiniciar
@onready var menu_button: Button = $Fondo/VBoxContainer/TituloPerdiste/Menu

func _ready() -> void:
	# Conecta las señales de los botones 
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	#  se guarden automáticamente las métricas acumuladas de la partida en el CSV
	Metrics.export_to_csv()

func _on_restart_pressed() -> void:
	#  Indica al addon que finaliza la sesión actual y arranca una nueva para el reinicio
	#Metrics.start_new_session()
	
	#  Recarga la escena actual del juego 
	get_tree().change_scene_to_file("res://escenas/escena_principal/escena_principal.tscn")

func _on_menu_pressed() -> void:
	#  Cierra la sesión actual de métricas
	#Metrics.start_new_session()
	
	# Volvemos al menú principal 
	get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")
