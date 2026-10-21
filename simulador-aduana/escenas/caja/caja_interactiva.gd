extends RigidBody3D

# Datos del pedido; su asset 3D se instancia dentro del nodo Marker3D puntoObjeto.
# El setter permite actualizar la caja cuando la escena principal asigna PedidoInfo.
@export var info: PedidoInfo:
	set = _set_info

var pedido_asociado: PedidoInfo = null
var caja_abierta: bool = false
var inspeccion_completada: bool = false
var cortador_activo: bool = false
var puede_cerrar_por_clic: bool = false
var malla_caja_original: Mesh
var posicion_camara_original: Vector3 = Vector3.ZERO
var rotacion_camara_original: Vector3 = Vector3.ZERO

@onready var punto_objeto: Node3D = $puntoObjeto
@onready var modelo_caja: Node3D = get_node_or_null("box-small2")
@onready var malla_caja: MeshInstance3D = get_node_or_null("box-small2/box-small")

# El setter carga el asset al asignarse los datos; centraliza el proceso con _ready().
func _set_info(datos: PedidoInfo) -> void:
	info = datos
	if is_node_ready():
		_actualizar_objeto_en_caja()

func _ready() -> void:
	# Permite que la caja reciba clics mediante el sistema de selección 3D.
	input_ray_pickable = true
	if malla_caja:
		malla_caja_original = malla_caja.mesh
	if punto_objeto:
		punto_objeto.hide()
	# Conecta la decisión final para iniciar la salida y liberar la caja del pedido.
	EventBus.decision_tomada.connect(_desaparecer_caja)
	# Si los datos se asignaron antes de entrar al árbol, _ready() carga el asset ahora.
	_actualizar_objeto_en_caja()

# Sustituye el contenido anterior por el asset 3D asociado al pedido actual.
func _actualizar_objeto_en_caja() -> void:
	if info == null or info.objeto_escena == null or punto_objeto == null:
		return

	# Limpia cualquier asset anterior si existiera.
	for hijo in punto_objeto.get_children():
		hijo.queue_free()
	# Instancia el asset dentro de puntoObjeto.
	var instancia_asset: Node = info.objeto_escena.instantiate()
	punto_objeto.add_child(instancia_asset)
	# Ajusta la escala del asset automáticamente para que no sobresalga de la caja.
	_ajustar_tamano_a_caja(instancia_asset, 0.4)
	# Sincroniza el ticket cuando esta caja ya está asociada a un pedido.
	if pedido_asociado != null:
		_aplicar_datos_al_ticket()

# Inicializa la caja con el pedido y sincroniza los datos impresos en el ticket.
func inicializar_caja(datos: PedidoInfo) -> void:
	pedido_asociado = datos
	info = datos
	_actualizar_objeto_en_caja()
	_aplicar_datos_al_ticket()

# Abre la tapa, revela el objeto y acerca la cámara para inspeccionarlo con el Cúter.
func abrir_caja() -> void:
	if not _pedido_detenido_en_inspeccion() or caja_abierta or inspeccion_completada or info == null:
		return
	caja_abierta = true
	# Separa las caras superiores de la malla para animarlas como una tapa y dejar la base.
	if malla_caja and malla_caja.mesh:
		var mesh_tapa: ArrayMesh = _crear_malla_tapa(malla_caja.mesh)
		if mesh_tapa:
			var nodo_tapa: MeshInstance3D = MeshInstance3D.new()
			nodo_tapa.name = "TapaCaja"
			nodo_tapa.mesh = mesh_tapa
			nodo_tapa.material_override = malla_caja.material_override
			modelo_caja.add_child(nodo_tapa)
			var malla_base: ArrayMesh = _crear_malla_base(malla_caja.mesh)
			if malla_base:
				malla_caja.mesh = malla_base
			var tween_tapa: Tween = create_tween()
			tween_tapa.tween_property(nodo_tapa, "position:y", 0.55, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			await tween_tapa.finished
			if is_instance_valid(nodo_tapa):
				nodo_tapa.queue_free()
	if punto_objeto:
		punto_objeto.show()
	cortador_activo = true
	# Se bloquea el cierre momentáneamente para que el clic que abrió la caja no la cierre.
	puede_cerrar_por_clic = false
	EventBus.inspeccion_visualizada.emit(info)
	_activar_vista_inspeccion()
	# Después de un segundo se permite salir del modo Cúter con un clic en cualquier lugar.
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(self) and caja_abierta:
		puede_cerrar_por_clic = true
	print("Caja abierta: contenido visible durante la inspección.")

# Restaura la caja cerrada y devuelve la cámara a la vista previa a la inspección.
func cerrar_caja() -> void:
	if not caja_abierta:
		return
	caja_abierta = false
	cortador_activo = false
	puede_cerrar_por_clic = false
	if punto_objeto:
		punto_objeto.hide()
	if malla_caja:
		malla_caja.show()
		if malla_caja_original:
			malla_caja.mesh = malla_caja_original
	if modelo_caja:
		var tapa_residual: Node = modelo_caja.get_node_or_null("TapaCaja")
		if tapa_residual:
			tapa_residual.queue_free()
	_restaurar_vista_camara()
	print("Caja cerrada; listo para decidir el pedido.")

# Anima el pivote de cámara de regreso a la posición y rotación guardadas.
func _restaurar_vista_camara() -> void:
	var escena_actual: Node = get_tree().current_scene
	var camara_pivote: Node3D = escena_actual.get_node_or_null("CameraPivot") as Node3D if escena_actual else null
	if camara_pivote == null:
		return
	var tween_camara: Tween = camara_pivote.create_tween()
	tween_camara.set_parallel(true)
	tween_camara.tween_property(camara_pivote, "position", posicion_camara_original, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_camara.tween_property(camara_pivote, "rotation", rotacion_camara_original, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Guarda el encuadre original y acerca la cámara a la caja para mostrar su contenido.
func _activar_vista_inspeccion() -> void:
	var escena_actual: Node = get_tree().current_scene
	if escena_actual == null:
		return
	var camara_pivote: Node3D = escena_actual.get_node_or_null("CameraPivot") as Node3D
	if camara_pivote == null:
		return
	posicion_camara_original = camara_pivote.position
	rotacion_camara_original = camara_pivote.rotation
	var tween_camara: Tween = camara_pivote.create_tween()
	var destino_posicion: Vector3 = global_position + Vector3(0.0, 2.8, 2.0)
	tween_camara.set_parallel(true)
	tween_camara.tween_property(camara_pivote, "global_position", destino_posicion, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_camara.tween_property(camara_pivote, "rotation", Vector3(deg_to_rad(-20.0), camara_pivote.rotation.y, 0.0), 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Registra que el jugador observó el paquete; no decide si lo aprueba o lo rechaza.
func inspeccionar_contenido() -> void:
	if not caja_abierta or inspeccion_completada or info == null:
		return
	inspeccion_completada = true
	EventBus.inspeccion_completada.emit(info)
	print("Inspección del contenido completada.")

func salir_del_cuter() -> void:
	cerrar_caja()

# Tras una decisión válida, cierra la presentación y elimina la caja de este pedido.
func _desaparecer_caja(_fue_permitido: bool) -> void:
	cerrar_caja()
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(self):
		queue_free()

# Busca el Ticket incluido en la escena de la caja y actualiza sus textos con el pedido.
func _aplicar_datos_al_ticket() -> void:
	if pedido_asociado == null:
		return
	var raiz_caja: Node = get_parent()
	var nodo_ticket: Node = raiz_caja.find_child("Ticket", true, false)
	if nodo_ticket and nodo_ticket.has_method("cargar_ticket"):
		nodo_ticket.cargar_ticket(pedido_asociado)

# El clic global permite cerrar la caja sin tener que acertar sobre su modelo 3D.
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if not caja_abierta or not cortador_activo or not puede_cerrar_por_clic:
		return
	var inventario: Inventario = get_tree().get_first_node_in_group("inventario") as Inventario
	cerrar_caja()
	if inventario:
		inventario.salir_del_cuter()
	get_viewport().set_input_as_handled()

# Comprueba que la cinta esté detenida en el punto de inspección.
func _pedido_detenido_en_inspeccion() -> bool:
	var escena_actual: Node = get_tree().current_scene
	var cinta: CintaTransportadora = escena_actual.get_node_or_null("Espacio_Trabajo/CintaTransportadora") as CintaTransportadora if escena_actual else null
	return cinta != null and cinta.estado == "INSPECCIONANDO" and cinta.caja_actual != null

# Emite la malla del paquete para mostrarla en el visor mientras el pedido está detenido.
func _escanear_contenido() -> void:
	if not _pedido_detenido_en_inspeccion() or info == null or cortador_activo or punto_objeto == null or punto_objeto.get_child_count() == 0:
		return
	var malla_escaner: Mesh = _obtener_mesh_del_asset(punto_objeto)
	if malla_escaner == null:
		push_warning("El pedido actual no contiene una malla que el escáner pueda mostrar.")
		return
	EventBus.escanear_objeto.emit(malla_escaner)

# El clic sobre la caja inicia la apertura únicamente cuando el Cúter está seleccionado.
func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if not _pedido_detenido_en_inspeccion():
		return
	if caja_abierta:
		return
	var inventario: Inventario = get_tree().get_first_node_in_group("inventario") as Inventario
	if inventario == null:
		return
	match inventario.get_herramienta_seleccionada():
		"cuter":
			abrir_caja()
		"escaner":
			_escanear_contenido()


# Conserva los triángulos que no pertenecen a la tapa.
func _crear_malla_base(malla_original: Mesh) -> ArrayMesh:
	return _crear_malla_filtrada(malla_original, false)

# Extrae la superficie superior para mostrarla brevemente como tapa animada.
func _crear_malla_tapa(malla_original: Mesh) -> ArrayMesh:
	return _crear_malla_filtrada(malla_original, true)

# Reconstruye la malla separando los triángulos de arriba del resto del modelo.
func _crear_malla_filtrada(malla_original: Mesh, solo_tapa: bool) -> ArrayMesh:
	if not (malla_original is ArrayMesh):
		return null
	var malla: ArrayMesh = malla_original as ArrayMesh
	if malla.get_surface_count() == 0:
		return null
	var arrays: Array = malla.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if vertices.is_empty():
		return null

	# La altura máxima del modelo permite reconocer los triángulos de la tapa.
	var max_y: float = -INF
	var tolerancia: float = 0.0001
	for vertice in vertices:
		max_y = maxf(max_y, vertice.y)

	var vertices_tapa: PackedVector3Array = PackedVector3Array()
	var normales_tapa: PackedVector3Array = PackedVector3Array()
	var colores_tapa: PackedColorArray = PackedColorArray()
	var uv_tapa: PackedVector2Array = PackedVector2Array()
	var indices_tapa: PackedInt32Array = PackedInt32Array()
	var colores: PackedColorArray = PackedColorArray()
	var uv: PackedVector2Array = PackedVector2Array()
	if arrays[Mesh.ARRAY_COLOR] is PackedColorArray:
		colores = arrays[Mesh.ARRAY_COLOR]
	if arrays[Mesh.ARRAY_TEX_UV] is PackedVector2Array:
		uv = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var triangulos: PackedInt32Array = indices if not indices.is_empty() else PackedInt32Array(range(vertices.size()))

	# Recorre la malla triángulo a triángulo y clasifica cada cara como tapa o base.
	for i in range(0, triangulos.size(), 3):
		if i + 2 >= triangulos.size():
			break
		var a: Vector3 = vertices[triangulos[i]]
		var b: Vector3 = vertices[triangulos[i + 1]]
		var c: Vector3 = vertices[triangulos[i + 2]]
		var triangulo_es_tapa: bool = absf(a.y - max_y) <= tolerancia and absf(b.y - max_y) <= tolerancia and absf(c.y - max_y) <= tolerancia
		if triangulo_es_tapa == solo_tapa:
			var inicio: int = vertices_tapa.size()
			vertices_tapa.append(a)
			vertices_tapa.append(b)
			vertices_tapa.append(c)
			if not colores.is_empty():
				colores_tapa.append(colores[triangulos[i]])
				colores_tapa.append(colores[triangulos[i + 1]])
				colores_tapa.append(colores[triangulos[i + 2]])
			if not uv.is_empty():
				uv_tapa.append(uv[triangulos[i]])
				uv_tapa.append(uv[triangulos[i + 1]])
				uv_tapa.append(uv[triangulos[i + 2]])
			var normal: Vector3 = (b - a).cross(c - a).normalized()
			normales_tapa.append(normal)
			normales_tapa.append(normal)
			normales_tapa.append(normal)
			indices_tapa.append(inicio)
			indices_tapa.append(inicio + 1)
			indices_tapa.append(inicio + 2)

	if vertices_tapa.is_empty():
		return null
	var arrays_filtradas: Array = []
	arrays_filtradas.resize(Mesh.ARRAY_MAX)
	arrays_filtradas[Mesh.ARRAY_VERTEX] = vertices_tapa
	arrays_filtradas[Mesh.ARRAY_NORMAL] = normales_tapa
	if not colores_tapa.is_empty():
		arrays_filtradas[Mesh.ARRAY_COLOR] = colores_tapa
	if not uv_tapa.is_empty():
		arrays_filtradas[Mesh.ARRAY_TEX_UV] = uv_tapa
	arrays_filtradas[Mesh.ARRAY_INDEX] = indices_tapa
	var malla_filtrada: ArrayMesh = ArrayMesh.new()
	malla_filtrada.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_filtradas)
	malla_filtrada.surface_set_material(0, malla.surface_get_material(0))
	return malla_filtrada

# Busca recursivamente la primera malla 3D del objeto para usos que la necesiten.
func _obtener_mesh_del_asset(nodo: Node) -> Mesh:
	if nodo is MeshInstance3D:
		var mesh_instancia: MeshInstance3D = nodo as MeshInstance3D
		if mesh_instancia.mesh != null:
			return mesh_instancia.mesh
	for hijo in nodo.get_children():
		var resultado: Mesh = _obtener_mesh_del_asset(hijo)
		if resultado != null:
			return resultado
	return null

# Reduce proporcionalmente el objeto si su dimensión mayor excede el espacio de la caja.
func _ajustar_tamano_a_caja(nodo: Node, limite_maximo: float) -> void:
	var mesh_instancia: MeshInstance3D = _buscar_mesh_instance(nodo)
	if mesh_instancia == null or mesh_instancia.mesh == null:
		return
	var tamano: Vector3 = mesh_instancia.mesh.get_aabb().size
	var tamano_maximo: float = max(tamano.x, max(tamano.y, tamano.z))
	if tamano_maximo > limite_maximo:
		var escala: float = limite_maximo / tamano_maximo
		nodo.scale = Vector3.ONE * escala

# Recorre la jerarquía importada del asset hasta encontrar su MeshInstance3D.
func _buscar_mesh_instance(nodo: Node) -> MeshInstance3D:
	if nodo is MeshInstance3D:
		return nodo as MeshInstance3D
	for hijo in nodo.get_children():
		var encontrado: MeshInstance3D = _buscar_mesh_instance(hijo)
		if encontrado != null:
			return encontrado
	return null
