extends RigidBody3D

# Aquí le decimos a la caja dónde escondimos el objeto.
# Busca el nodo Marker3D y luego el dibujo de adentro.
@onready var punto_objeto: Node3D = $puntoObjeto

@export var info: PedidoInfo

func _ready():
	# Le decimos a la caja que escuche el megáfono del EventBus
	# para saber en qué momento tomaste la decisión
	EventBus.decision_tomada.connect(_desaparecer_caja)
	
	# Si la caja recibió un PedidoInfo con un asset 3D asignado
	if info and info.objeto_escena:
		# Instanciamos el asset dentro de puntoObjeto
		var instancia_asset = info.objeto_escena.instantiate()
		punto_objeto.add_child(instancia_asset)


func _desaparecer_caja(_fue_permitido: bool) -> void:
	# Al presionar cualquier botón, espera 1 segundo y se destruye si fue denegada
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(self):
		queue_free()
	print("La caja fue destruida de la escena.")

# Esta función salta cuando haces clic en la caja de afuera
func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Buscamos la malla del asset instanciado para enviársela al escáner
		var mesh_para_escanear: Mesh = _obtener_mesh_del_asset(punto_objeto)
		
		if mesh_para_escanear:
			EventBus.escanear_objeto.emit(mesh_para_escanear)

# Busca el MeshInstance3D dentro del .gltf que cargó el recurso
func _obtener_mesh_del_asset(nodo: Node) -> Mesh:
	for child in nodo.get_children():
		if child is MeshInstance3D and child.mesh != null:
			return child.mesh
		var resultado_subnodo = _obtener_mesh_del_asset(child)
		if resultado_subnodo != null:
			return resultado_subnodo
	return null
