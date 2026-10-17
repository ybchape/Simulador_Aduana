extends RigidBody3D

# Aquí le decimos a la caja dónde escondimos el objeto.
# Busca el nodo Marker3D y luego el dibujo de adentro.
@onready var objeto_secreto = $puntoObjeto/MeshInstance3D
var pedido_asociado: PedidoInfo = null

func _ready():
	EventBus.decision_tomada.connect(_desaparecer_caja)

	 #Si ya teníamos datos guardados antes de estar en el árbol, los aplicamos ahora
	if pedido_asociado != null:
		_aplicar_datos_al_ticket()

func _desaparecer_caja(_fue_permitido: bool) -> void:
	# Al presionar cualquier botón, espera 1 segundo y se destruye si fue denegada
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(self):
		queue_free()
	print("La caja fue destruida de la escena.")

# Esta función salta cuando haces clic en la caja de afuera
func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	# ¿El evento fue un clic del mouse?
	if event is InputEventMouseButton:
		# ¿Fue el botón izquierdo y se acaba de presionar?
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Le pedimos la forma al objeto que escondimos adentro
			var forma_secreta = objeto_secreto.mesh
			# Llamamos al Bus de Eventos para que la pantalla aparezca
			EventBus.escanear_objeto.emit(forma_secreta)

# Función que llama la escena principal
func inicializar_caja(datos: PedidoInfo) -> void:
	pedido_asociado = datos
	_aplicar_datos_al_ticket()

func _aplicar_datos_al_ticket() -> void:
	if pedido_asociado == null:
		return
	# Buscamos el nodo Ticket desde la raíz de la caja de forma automática
	var nodo_raiz = get_parent()
	var nodo_ticket = nodo_raiz.find_child("Ticket", true, false)
	if nodo_ticket and nodo_ticket.has_method("cargar_ticket"):
		nodo_ticket.cargar_ticket(pedido_asociado)
		print("DATOS ENVIADOS AL TICKET")
	else:
		print("Advertencia: No se encontró el nodo Ticket.")
	if nodo_ticket and nodo_ticket.has_method("cargar_ticket"):
		nodo_ticket.cargar_ticket(pedido_asociado)
		print("Ticket encontrado y actualizado ")
	else:
		print("No se pudo hallar el nodo Ticket en la caja.")

# Función auxiliar para buscar el nodo sin importar la ruta exacta
func _encontrar_nodo_por_nombre(raiz: Node, nombre: String) -> Node:
	if raiz.name == nombre:
		return raiz
	for hijo in raiz.get_children():
		var encontrado = _encontrar_nodo_por_nombre(hijo, nombre)
		if encontrado:
			return encontrado
	return null
