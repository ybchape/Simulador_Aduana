extends Control

# Ruta a la escena del menú principal 
@export_file("*.tscn") var menu_principal_path: String = "res://escenas/menu_principal.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_volver_pressed() -> void:
	if menu_principal_path != "":
		var resultado = get_tree().change_scene_to_file(menu_principal_path)
		if resultado != OK:
			print("Error al cargar el menú principal. Código: ", resultado)
	else:
		print("No se configuró la ruta al menú principal.")
