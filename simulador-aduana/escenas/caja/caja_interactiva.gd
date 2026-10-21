extends RigidBody3D

# Aquí le decimos a la caja dónde escondimos el objeto.
# Busca el nodo Marker3D y luego el dibujo de adentro.

var pedido_asociado: PedidoInfo = null
@onready var punto_objeto: Node3D = $puntoObjeto

# Al usar set(val), ejecuta la carga del asset en cuanto la escena principal asigna la info
@export var info: PedidoInfo:
	set = _set_info

func _set_info(val: PedidoInfo) -> void:
	info = val
	_actualizar_objeto_en_caja()
			
func _ready():
	EventBus.decision_tomada.connect(_desaparecer_caja)
	
	# Carga el asset 3D en caso de que la información ya estuviera asignada antes de _ready()
	_actualizar_objeto_en_caja()

# Centraliza la instanciación para que no se duplique entre _ready() y el set(val)
func _actualizar_objeto_en_caja() -> void:
	# Si el nodo punto_objeto todavía no entró al árbol, espera un milisegundo a que esté listo
	if not is_node_ready():
		await ready

	# Si la caja recibió un PedidoInfo con un asset 3D asignado
	if info and info.objeto_escena and punto_objeto:
		# Limpia cualquier asset anterior si existiera
		for child in punto_objeto.get_children():
			child.queue_free()
			
		# Instancia el asset dentro de puntoObjeto
		var instancia_asset = info.objeto_escena.instantiate()
		punto_objeto.add_child(instancia_asset)
		
		# Ajusta la escala del asset automáticamente para que no sobresalga de la caja
		_ajustar_tamano_a_caja(instancia_asset, 0.4)


	 #Si ya teníamos datos guardados antes de estar en el árbol, los aplicamos ahora
	if pedido_asociado != null:
		_aplicar_datos_al_ticket()

func _desaparecer_caja(_fue_permitido: bool) -> void:
	# Al presionar cualquier botón, espera 1 segundo y se destruye si fue denegada
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(self):
		queue_free()
	print("La caja fue destruida de la escena.")
  

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
