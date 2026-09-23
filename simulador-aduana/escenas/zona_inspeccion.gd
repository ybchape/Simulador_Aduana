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
	if body.is_in_group("cajas"):
		
		# Le gritamos al EventBus que la caja llegó. ¡Los botones se activarán!
		EventBus.pedido_en_zona.emit(true)
		print("¡Sensor: Una caja entró a la zona de inspección!")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("cajas"):
		
		# Le gritamos al EventBus que ya no hay caja. ¡Los botones se bloquean!
		EventBus.pedido_en_zona.emit(false)
		print("¡Sensor: La caja se fue!")
