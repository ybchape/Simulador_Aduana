extends Area3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Esta función salta automáticamente cuando ALGO entra al sensor
func _on_body_entered(body: Node3D) -> void:
	# Le preguntamos a ese "algo": ¿tienes la etiqueta 'cajas'?
	if body.is_in_group("cajas")or body.name.begins_with("caja"):
		
		# El punto final de la cinta confirma la parada y habilita los controles.
		print("Sensor de inspección: caja detectada.")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("cajas")or body.name.begins_with("caja"):
		
		# La cinta notifica cuándo abandona el punto de inspección.
		print("Sensor de inspección: caja retirada.")
