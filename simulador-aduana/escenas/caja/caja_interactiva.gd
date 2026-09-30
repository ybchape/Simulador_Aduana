extends RigidBody3D

# aca le decimos a la caja donde esta el objeto
# buscamosel nodo Marker3D y despues el objeto de adentro
@onready var objeto_secreto = $puntoObjeto/MeshInstance3D
#@onready var lbl_titulo: Label = $MarginContainer/VBoxContainer/LblTitulo
#@onready var lbl_producto: Label = $MarginContainer/VBoxContainer/LblProducto
#@onready var lbl_peso: Label = $MarginContainer/VBoxContainer/LblPeso
#@onready var lbl_codigo: Label = $MarginContainer/VBoxContainer/LblCodigo

# Esta función salta cuando haces clic en la caja de afuera
func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	# chequea si el evento fue un clic del mouse
	if event is InputEventMouseButton:

		# chequea si fue el botón izquierdo y si se acaba de presionar
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			# nos pasa la forma al objeto que escondimos adentro
			var forma_secreta = objeto_secreto.mesh

			# llamamos al Bus de Eventos para que la pantalla aparezca
			EventBus.escanear_objeto.emit(forma_secreta)

# Función para cargar y mostrar los datos del pedido en el ticket 2D
func cargar_datos_ticket(datos: PedidoInfo) -> void:
	if datos == null:
		return
