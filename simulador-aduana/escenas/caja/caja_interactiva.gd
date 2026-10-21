class_name CajaInteractiva
extends RigidBody3D

# Pedido y malla del paquete cargados en el marcador interior.
@export var info: PedidoInfo:
	set = _set_info

var pedido_asociado: PedidoInfo = null
var caja_abierta: bool = false
var cortador_activo: bool = false
var puede_cerrar_por_clic: bool = false
var malla_caja_original: Mesh
var posicion_camara_original: Vector3 = Vector3.ZERO
var rotacion_camara_original: Vector3 = Vector3.ZERO
var tapa_original: Mesh
var material_tapa_original: Material
var tapa_abierta: MeshInstance3D
var posicion_camara_original_global: Vector3 = Vector3.ZERO
var escala_camara_original: float = 75.0
var visibilidad_malla_original: bool = true
var inspeccion_en_proceso: bool = false

@onready var punto_objeto: Node3D = $puntoObjeto
@onready var modelo_caja: Node3D = get_node_or_null("box-small2")
@onready var malla_caja: MeshInstance3D = _buscar_mesh_instance(modelo_caja) if modelo_caja else null

func _set_info(datos: PedidoInfo) -> void:
	info = datos
	if is_node_ready():
		_actualizar_objeto_en_caja()

func _ready() -> void:
	input_ray_pickable = true
	if malla_caja:
		malla_caja_original = malla_caja.mesh
	EventBus.decision_tomada.connect(_desaparecer_caja)
	_actualizar_objeto_en_caja()

# Mantiene un solo objeto hijo y sincroniza la etiqueta del pedido.
func _actualizar_objeto_en_caja() -> void:
	if info == null or info.objeto_escena == null or punto_objeto == null:
		return
	for hijo in punto_objeto.get_children():
		if hijo.name != "Area3D":
			hijo.queue_free()
	var instancia_asset: Node = info.objeto_escena.instantiate()
	punto_objeto.add_child(instancia_asset)
	_ajustar_tamano_a_caja(instancia_asset, 0.4)
	if pedido_asociado != null:
		_aplicar_datos_al_ticket()

func inicializar_caja(datos: PedidoInfo) -> void:
	pedido_asociado = datos
	info = datos
	_aplicar_datos_al_ticket()

func _aplicar_datos_al_ticket() -> void:
	if pedido_asociado == null:
		return
	var nodo_ticket: Node = get_parent().find_child("Ticket", true, false)
	if nodo_ticket and nodo_ticket.has_method("cargar_ticket"):
		nodo_ticket.cargar_ticket(pedido_asociado)

# Solo permite inspeccionar si esta caja es la actual y la cinta está detenida.
func _pedido_detenido_en_inspeccion() -> bool:
	var escena_actual: Node = get_tree().current_scene
	var cinta: Node = escena_actual.get_node_or_null("Espacio_Trabajo/CintaTransportadora") if escena_actual else null
	if cinta == null:
		return false
	var caja_actual: Node = cinta.get("caja_actual") as Node
	var estado_cinta: String = cinta.get("estado") as String
	var caja_raiz: Node = get_parent()
	return caja_actual == caja_raiz and estado_cinta == "INSPECCIONANDO"

# Abre la tapa del paquete y revela el objeto sin tomar la decisión de aprobarlo.
func abrir_caja() -> void:
	if not _pedido_detenido_en_inspeccion() or caja_abierta or inspeccion_en_proceso or info == null:
		return
	inspeccion_en_proceso = true
	caja_abierta = true
	puede_cerrar_por_clic = false
	cortador_activo = true
	if malla_caja == null or malla_caja.mesh == null:
		push_warning("No se encontró la malla de la caja para abrirla.")
		caja_abierta = false
		cortador_activo = false
		inspeccion_en_proceso = false
		return

	# Conserva el modelo original y deja visible el cuerpo mientras separa la tapa.
	tapa_original = malla_caja.mesh
	material_tapa_original = malla_caja.material_override
	visibilidad_malla_original = malla_caja.visible
	var base_abierta: ArrayMesh = _crear_malla_filtrada(tapa_original, false)
	var tapa: ArrayMesh = _crear_malla_tapa(tapa_original)
	if base_abierta == null or tapa == null:
		push_warning("No se pudo separar tapa y cuerpo; se conserva la caja cerrada.")
		caja_abierta = false
		cortador_activo = false
		tapa_original = null
		inspeccion_en_proceso = false
		return
	malla_caja.mesh = base_abierta
	malla_caja.show()

	# Crea una tapa temporal visible que sube y se retira de la escena.
	tapa_abierta = MeshInstance3D.new()
	tapa_abierta.name = "TapaCajaAbierta"
	tapa_abierta.mesh = tapa
	tapa_abierta.transform = malla_caja.transform
	var bounds_caja: AABB = tapa_original.get_aabb()
	tapa_abierta.position.y = bounds_caja.position.y + bounds_caja.size.y
	var material_base: Material = malla_caja.get_active_material(0)
	if material_base:
		tapa_abierta.material_override = material_base.duplicate() as Material
	modelo_caja.add_child(tapa_abierta)
	var posicion_tapa_inicial: Vector3 = tapa_abierta.position
	var tween_tapa: Tween = create_tween()
	tween_tapa.tween_property(tapa_abierta, "position", posicion_tapa_inicial + Vector3.UP * 0.8, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween_tapa.finished
	if not is_instance_valid(self) or not caja_abierta:
		inspeccion_en_proceso = false
		return
	if is_instance_valid(tapa_abierta):
		tapa_abierta.queue_free()
	tapa_abierta = null

	if punto_objeto:
		punto_objeto.show()
	# La cámara cambia solo después de retirar la tapa, manteniendo foco en esta caja.
	_activar_vista_inspeccion()
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(self) and caja_abierta:
		puede_cerrar_por_clic = true
	inspeccion_en_proceso = false

# Registra que se vio el paquete; la aprobación o rechazo sigue en los botones.
func inspeccionar_contenido() -> void:
	if caja_abierta:
		EventBus.inspeccion_completada.emit(info)

func cerrar_caja() -> void:
	if not caja_abierta:
		return
	var fue_inspeccionada: bool = cortador_activo
	caja_abierta = false
	cortador_activo = false
	puede_cerrar_por_clic = false
	if punto_objeto:
		punto_objeto.hide()
	if malla_caja and tapa_original:
		malla_caja.mesh = tapa_original
		malla_caja.material_override = material_tapa_original
		malla_caja.visible = visibilidad_malla_original
		tapa_original = null
	elif malla_caja:
		malla_caja.show()
	if is_instance_valid(tapa_abierta):
		tapa_abierta.queue_free()
	tapa_abierta = null
	_restaurar_vista_camara()
	if fue_inspeccionada:
		var inventario: Inventario = get_tree().get_first_node_in_group("inventario") as Inventario
		if inventario:
			inventario.salir_del_cuter()

func _activar_vista_inspeccion() -> void:
	var escena_actual: Node = get_tree().current_scene
	var camara_pivote: Node3D = escena_actual.get_node_or_null("CameraPivot") as Node3D if escena_actual else null
	if camara_pivote == null:
		return
	var camara: Camera3D = camara_pivote.get_node_or_null("Camera3D") as Camera3D
	posicion_camara_original = camara_pivote.position
	posicion_camara_original_global = camara_pivote.global_position
	rotacion_camara_original = camara_pivote.rotation
	if camara:
		escala_camara_original = camara.fov
	# Acerca la cámara hacia la caja y baja ligeramente la vista, igual que en el flujo anterior.
	# Desplaza la cámara adelante y un poco arriba para dar una vista más cenital del contenido.
	var posicion_objetivo: Vector3 = posicion_camara_original + Vector3(0.0, 0.45, -1.65)
	var rotacion_objetivo: Vector3 = rotacion_camara_original + Vector3(deg_to_rad(-44.0), 0.0, 0.0)
	var tween_camara: Tween = camara_pivote.create_tween()
	tween_camara.set_parallel(true)
	tween_camara.tween_property(camara_pivote, "position", posicion_objetivo, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_camara.tween_property(camara_pivote, "rotation", rotacion_objetivo, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if camara:
		tween_camara.tween_property(camara, "fov", maxf(45.0, escala_camara_original - 14.0), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _restaurar_vista_camara() -> void:
	var escena_actual: Node = get_tree().current_scene
	var camara_pivote: Node3D = escena_actual.get_node_or_null("CameraPivot") as Node3D if escena_actual else null
	if camara_pivote == null:
		return
	var camara: Camera3D = camara_pivote.get_node_or_null("Camera3D") as Camera3D
	var tween_camara: Tween = camara_pivote.create_tween()
	tween_camara.set_parallel(true)
	tween_camara.tween_property(camara_pivote, "position", posicion_camara_original, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_camara.tween_property(camara_pivote, "rotation", rotacion_camara_original, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if camara:
		tween_camara.tween_property(camara, "fov", escala_camara_original, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _desaparecer_caja(_fue_permitido: bool) -> void:
	cerrar_caja()
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(self):
		queue_free()

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if not caja_abierta or not cortador_activo or not puede_cerrar_por_clic:
		return
	cerrar_caja()
	get_viewport().set_input_as_handled()

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if not _pedido_detenido_en_inspeccion():
		return
	var inventario: Inventario = get_tree().get_first_node_in_group("inventario") as Inventario
	if inventario == null:
		push_warning("No se encontró el inventario para usar la herramienta seleccionada.")
		return
	match inventario.get_herramienta_seleccionada():
		"escaner":
			escanear_contenido()
		"cuter":
			abrir_caja()

# Envía la malla del contenido al EventBus; no abre ni decide el pedido.
func escanear_contenido() -> void:
	if not _pedido_detenido_en_inspeccion() or caja_abierta or punto_objeto.get_child_count() == 0:
		return
	var mesh_paquete: Mesh = _obtener_mesh_del_asset(punto_objeto)
	if mesh_paquete == null:
		push_warning("No se encontró una malla para mostrar en el escáner.")
		return
	EventBus.escanear_objeto.emit(mesh_paquete)

# La caja GLB no tiene una tapa independiente, así que crea una placa temporal arriba.
func _crear_malla_tapa(malla_original: Mesh) -> ArrayMesh:
	var caja_mesh: BoxMesh = BoxMesh.new()
	var dimensiones: Vector3 = malla_original.get_aabb().size
	caja_mesh.size = Vector3(dimensiones.x, 0.025, dimensiones.z)
	var resultado: ArrayMesh = ArrayMesh.new()
	resultado.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, caja_mesh.surface_get_arrays(0))
	resultado.surface_set_material(0, malla_original.surface_get_material(0))
	return resultado

# Separa los triángulos superiores del resto para poder levantar la tapa.
func _crear_malla_filtrada(malla_original: Mesh, solo_tapa: bool) -> ArrayMesh:
	if not (malla_original is ArrayMesh):
		return null
	var malla: ArrayMesh = malla_original as ArrayMesh
	if malla.get_surface_count() == 0:
		return null
	var arrays: Array = malla.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices_originales: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var triangulos: PackedInt32Array = indices_originales if not indices_originales.is_empty() else PackedInt32Array(range(vertices.size()))
	var normales_originales: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs_originales: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var altura_maxima: float = -INF
	for vertice in vertices:
		altura_maxima = maxf(altura_maxima, vertice.y)
	var vertices_filtrados: PackedVector3Array = PackedVector3Array()
	var normales_filtradas: PackedVector3Array = PackedVector3Array()
	var uvs_filtradas: PackedVector2Array = PackedVector2Array()
	var indices_filtrados: PackedInt32Array = PackedInt32Array()
	for i in range(0, triangulos.size(), 3):
		if i + 2 >= triangulos.size():
			break
		var ia: int = triangulos[i]
		var ib: int = triangulos[i + 1]
		var ic: int = triangulos[i + 2]
		var a: Vector3 = vertices[ia]
		var b: Vector3 = vertices[ib]
		var c: Vector3 = vertices[ic]
		var normal_triangulo: Vector3 = (b - a).cross(c - a).normalized()
		var es_superficie_superior: bool = absf(a.y - altura_maxima) < 0.0001 and absf(b.y - altura_maxima) < 0.0001 and absf(c.y - altura_maxima) < 0.0001
		if es_superficie_superior == solo_tapa:
			var inicio: int = vertices_filtrados.size()
			for indice in [ia, ib, ic]:
				vertices_filtrados.append(vertices[indice])
				if normales_originales.size() == vertices.size():
					normales_filtradas.append(normales_originales[indice])
				else:
					normales_filtradas.append(normal_triangulo)
				if uvs_originales.size() == vertices.size():
					uvs_filtradas.append(uvs_originales[indice])
			indices_filtrados.append_array(PackedInt32Array([inicio, inicio + 1, inicio + 2]))
	if vertices_filtrados.is_empty():
		return null
	var arrays_filtrados: Array = []
	arrays_filtrados.resize(Mesh.ARRAY_MAX)
	arrays_filtrados[Mesh.ARRAY_VERTEX] = vertices_filtrados
	arrays_filtrados[Mesh.ARRAY_NORMAL] = normales_filtradas
	arrays_filtrados[Mesh.ARRAY_TEX_UV] = uvs_filtradas
	arrays_filtrados[Mesh.ARRAY_INDEX] = indices_filtrados
	var resultado: ArrayMesh = ArrayMesh.new()
	resultado.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_filtrados)
	resultado.surface_set_material(0, malla.surface_get_material(0))
	return resultado

# Encuentra la primera malla en la jerarquía del asset importado.
func _obtener_mesh_del_asset(nodo: Node) -> Mesh:
	var instancia: MeshInstance3D = _buscar_mesh_instance(nodo)
	return instancia.mesh if instancia else null

func _ajustar_tamano_a_caja(nodo: Node, limite_maximo: float) -> void:
	var instancia: MeshInstance3D = _buscar_mesh_instance(nodo)
	if instancia == null or instancia.mesh == null:
		return
	var tamano: Vector3 = instancia.mesh.get_aabb().size
	var maximo: float = maxf(tamano.x, maxf(tamano.y, tamano.z))
	if maximo > limite_maximo:
		nodo.scale = Vector3.ONE * (limite_maximo / maximo)

func _buscar_mesh_instance(nodo: Node) -> MeshInstance3D:
	if nodo is MeshInstance3D:
		return nodo as MeshInstance3D
	for hijo in nodo.get_children():
		var encontrado: MeshInstance3D = _buscar_mesh_instance(hijo)
		if encontrado:
			return encontrado
	return null
