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
# Ajusta la escala del asset automáticamente para que no sobresalga de la caja
		_ajustar_tamano_a_caja(instancia_asset, 0.4)

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

# Calcula el tamaño 3D de la malla y reduce la escala si supera el límite de la caja
func _ajustar_tamano_a_caja(nodo: Node, limite_maximo: float) -> void:
	var mesh_inst: MeshInstance3D = _buscar_mesh_instance(nodo)
	if mesh_inst and mesh_inst.mesh:
		var aabb = mesh_inst.mesh.get_aabb()
		var tamano_actual = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		
		if tamano_actual > limite_maximo:
			var factor_escala = limite_maximo / tamano_actual
			nodo.scale = Vector3(factor_escala, factor_escala, factor_escala)


# Busca el nodo MeshInstance3D dentro del asset importado para calcular su caja delimitadora
func _buscar_mesh_instance(nodo: Node) -> MeshInstance3D:
	if nodo is MeshInstance3D:
		return nodo
	for child in nodo.get_children():
		var res = _buscar_mesh_instance(child)
		if res != null:
			return res
	return null
