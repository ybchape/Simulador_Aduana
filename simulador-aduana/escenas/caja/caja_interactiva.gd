extends RigidBody3D

# Aquí le decimos a la caja dónde escondimos el objeto.
# Busca el nodo Marker3D y luego el dibujo de adentro.
@onready var objeto_secreto = $puntoObjeto/MeshInstance3D

# Esta función salta cuando haces clic en la caja de afuera
func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	# 1. Preguntamos: ¿El evento fue un clic del mouse?
	if event is InputEventMouseButton:
		
		# 2. Preguntamos: ¿Fue el botón izquierdo y se acaba de presionar?
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			
			# 3. Le pedimos la forma al objeto que escondimos adentro
			var forma_secreta = objeto_secreto.mesh
			
			# 4. Gritamos por el Bus de Eventos para que la pantalla aparezca
			EventBus.escanear_objeto.emit(forma_secreta)
