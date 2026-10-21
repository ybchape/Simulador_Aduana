extends Node3D

# Ref a la instancia de la planilla dentro del CanvasLayer
@onready var planilla_ui: Control = $UIPlanilla/PlanillaUI

# Precargamos la escena de la caja para poder instanciar news pedidos por código
const CAJA_ESCENA = preload("res://escenas/caja/caja.tscn")

# Listas de control de historial (para que no se repitan los pedidos)
static var indices_legales_disponibles: Array[int] = []
static var indices_ilegales_disponibles: Array[int] = []

# Precargamos las mallas 3D de los assets 
var mallas_legales: Array[PackedScene] = [
	preload("res://assets/muebles/gltf/cactus_medium_B.gltf"),
	preload("res://assets/muebles/gltf/book_set.gltf"),
	preload("res://assets/muebles/gltf/cabinet_small.gltf"),
	preload("res://assets/muebles/gltf/chair_A.gltf"),
	preload("res://assets/muebles/gltf/lamp_table.gltf"),
	preload("res://assets/muebles/gltf/pictureframe_small_A.gltf"),
	preload("res://assets/muebles/gltf/pillow_A.gltf"),
	preload("res://assets/muebles/gltf/rug_oval_A.gltf"),
	preload("res://assets/muebles/gltf/shelf_B_large.gltf"),
	preload("res://assets/muebles/gltf/table_small.gltf"),
	preload("res://assets/herramientas/gltf/lantern.gltf"),
	preload("res://assets/herramientas/gltf/magnifying_glass.gltf"),
	preload("res://assets/herramientas/gltf/pencil_B_long.gltf"),
	preload("res://assets/herramientas/gltf/scissors.gltf"),
	preload("res://assets/herramientas/gltf/shovel.gltf"),
]
var nombres_legales: Array[String] = ["Planta Decorativa", "Libros" , "Mesita de Luz" , "Sillita" ,
 "Velador" , "Cuadro de Fotos" , "Almohada" , "Alfombra" , "Repisa" , "Mesita" , "Luz de Exterior" ,
"Lupa" , "Lápiz" , "Tijeras" , "Pala"
]

var mallas_ilegales: Array[PackedScene] = [
	preload("res://assets/armas/gltf/hammer_C.gltf"),
	preload("res://assets/armas/gltf/sword_C.gltf"),
	preload("res://assets/armas/gltf/axe_B.gltf"),
	preload("res://assets/armas/gltf/fistweapon_A_stacked.gltf"),
	preload("res://assets/armas/gltf/hammer_B.gltf"),
	preload("res://assets/armas/gltf/sword_E.gltf"),
	preload("res://assets/herramientas/gltf/knife.gltf"),
	preload("res://assets/herramientas/gltf/saw.gltf"),
]
var nombres_ilegales: Array[String] = ["Maza con Pinches", "Daga" , "Hacha" , "Manoplas" , "Martillo" ,
 "Espada" , "Cuchillo" , "Serrucho" , ]


# save el pedido activo actual 
var pedido_actual: PedidoInfo = null

func _ready() -> void:
	EventBus.decision_tomada.connect(_on_decision_tomada)
	if indices_legales_disponibles.is_empty() and indices_ilegales_disponibles.is_empty():
		_reiniciar_bolsas_de_objetos() #si ya no hay mas objetos se reinician
	#probar_carga_pedido()

	# genera el pedido para la primera caja que ya está en la escena
	_generar_y_cargar_nuevo_pedido()

	# buscamos la caja inicial en el árbol y le pasamos los datos
	var caja_inicial = $Espacio_Trabajo/caja 
	if caja_inicial:
		var script_caja = caja_inicial.get_node_or_null("caja_interactiva")
		if script_caja and script_caja.has_method("inicializar_caja"):
			script_caja.inicializar_caja(pedido_actual)

	# registra la caja inicial en la cinta transportadora
	$Espacio_Trabajo/CintaTransportadora.registrar_caja(caja_inicial)

	EventBus.siguiente_pedido_solicitado.connect(_on_siguiente_pedido_solicitado)

	# Se conecta a decision_tomada para procesar aciertos/errores en GameManager 
	#EventBus.decision_tomada.connect(_on_decision_tomada)
	
	#_generar_y_cargar_nuevo_pedido()
	
	#$Espacio_Trabajo/CintaTransportadora.registrar_caja($Espacio_Trabajo/caja)
	
	# Conectamos la señal del EventBus para que al terminar de salir una caja, se pida la siguiente
	#EventBus.siguiente_pedido_solicitado.connect(_on_siguiente_pedido_solicitado)



# Llena las bolsas de índices para elegir sin repetir
func _reiniciar_bolsas_de_objetos() -> void:
	indices_legales_disponibles.clear()
	for i in range(mallas_legales.size()):
		indices_legales_disponibles.append(i)
	indices_legales_disponibles.shuffle()

	indices_ilegales_disponibles.clear()
	for i in range(mallas_ilegales.size()):
		indices_ilegales_disponibles.append(i)
	indices_ilegales_disponibles.shuffle()

# Obtiene un índice sin repetir de la bolsa legal (Pedidoslegales)
func _obtener_indice_legal_unico() -> int:
	if indices_legales_disponibles.is_empty():
		_reiniciar_bolsas_de_objetos()
	return indices_legales_disponibles.pop_back()

# Obtiene un índice sin repetir de la bolsa ilegal (Pedidos ilegales)
func _obtener_indice_ilegal_unico() -> int:
	if indices_ilegales_disponibles.is_empty():
		_reiniciar_bolsas_de_objetos()
	return indices_ilegales_disponibles.pop_back()


#func probar_carga_pedido() -> void:
# Crea el primer PedidoInfo usando el sistema de bolsas sin repetición
	#var pedido_test = PedidoInfo.new()
	#pedido_test.es_ilegal = randf() < 0.3
	
	#if pedido_test.es_ilegal:
		#var idx = _obtener_indice_ilegal_unico()
		#pedido_test.nombre_producto = nombres_ilegales[idx]
		#pedido_test.objeto_escena = mallas_ilegales[idx]
	#else:
		#var idx = _obtener_indice_legal_unico()
		#pedido_test.nombre_producto = nombres_legales[idx]
		#pedido_test.objeto_escena = mallas_legales[idx]
		
	#pedido_test.peso_kg = snappedf(randf_range(10.0, 30.0), 0.001)
	#pedido_test.codigo_identificador = "RF-396 VY"

	# Asignam el recurso a la caja inicial que ya está en la escena
	#if has_node("Espacio_Trabajo/caja/caja_interactiva"):
		#$Espacio_Trabajo/caja/caja_interactiva.info = pedido_test
		
	# Lo envía a la planilla para que actualice sus datos
	#if planilla_ui:
		#planilla_ui.cargar_pedido(pedido_test)
	#else:
		#print("Error: No se encontró la PlanillaUI en la ruta especificada.")

func _on_boton_tienda_pressed() -> void:
	$CanvasLayer/tienda.show()

# Procesa la aprobación o denegación cuando el jugador presiona un botón 
func _on_decision_tomada(fue_permitido: bool) -> void:
	if pedido_actual == null:
		return

	if fue_permitido:
		GameManager.procesar_aprobar_paquete(pedido_actual.es_ilegal)
	else:
		GameManager.procesar_denegar_paquete(pedido_actual.es_ilegal)

# Func que crea la siguiente caja y genera datos aleatorios
func _on_siguiente_pedido_solicitado() -> void:
	var nueva_caja = CAJA_ESCENA.instantiate()
	#var pedido_nuevo = PedidoInfo.new()

	_generar_y_cargar_nuevo_pedido()

	# add como hija dentro del nodo contenedor (Espacio_Trabajo)
	$Espacio_Trabajo.add_child(nueva_caja)

	_generar_y_cargar_nuevo_pedido()

	# Buscamos el nodo hijo 'caja_interactiva' que tiene el script
	var script_caja = nueva_caja.get_node_or_null("caja_interactiva")
	if script_caja and script_caja.has_method("inicializar_caja"):
		script_caja.inicializar_caja(pedido_actual)
	else:
		print("Error: No se encontró el nodo caja_interactiva en la nueva caja.")
	
	#if pedido_nuevo.es_ilegal:
		#var idx = _obtener_indice_ilegal_unico()
		#pedido_nuevo.nombre_producto = nombres_ilegales[idx]
		#pedido_nuevo.objeto_escena = mallas_ilegales[idx]
	#else:
		#var idx = _obtener_indice_legal_unico()
		#pedido_nuevo.nombre_producto = nombres_legales[idx]
		#pedido_nuevo.objeto_escena = mallas_legales[idx]

	$Espacio_Trabajo/CintaTransportadora.registrar_caja(nueva_caja)

	# Si la caja tiene la función para inicializarse con el pedido, se la llama
	#if nueva_caja.has_method("inicializar_caja"):
		#nueva_caja.inicializar_caja(pedido_actual)
	# registra la nueva caja en la cinta para que comience su recorrido de entrada
	#$Espacio_Trabajo/CintaTransportadora.registrar_caja(nueva_caja)#

# generación de datos aleatorios para comparar Planilla con ek Ticket 
func _generar_y_cargar_nuevo_pedido() -> void:
	pedido_actual = PedidoInfo.new()
	#var productos_posibles = ["Alfajor", "Cocaína", "BMO", "Copa", "Microondas"]
	# Determinar si el paquete será ilegal (30% de probabilidad)
	pedido_actual.es_ilegal = randf() < 0.3
	
	# Asigna el modelo 3D y el nombre según el historial sin repetición
	if pedido_actual.es_ilegal:
		var idx = _obtener_indice_ilegal_unico()
		pedido_actual.nombre_producto = nombres_ilegales[idx]
		pedido_actual.objeto_escena = mallas_ilegales[idx]
	else:
		var idx = _obtener_indice_legal_unico()
		pedido_actual.nombre_producto = nombres_legales[idx]
		pedido_actual.objeto_escena = mallas_legales[idx]
	
	# Datos reales / Planilla

	pedido_actual.peso_kg = snappedf(randf_range(10.0, 30.0), 0.001)
	pedido_actual.codigo_identificador = "RF-" + str(randi_range(100, 999)) + " VY"



	if pedido_actual.es_ilegal:
		# Alterar alguno de los datos del Ticket para crear la discrepancia
		var tipo_error = randi() % 3
		if tipo_error == 0:
			pedido_actual.ticket_producto = "Producto Prohibido"
			pedido_actual.ticket_peso_kg = pedido_actual.peso_kg
			pedido_actual.ticket_codigo_identificador = pedido_actual.codigo_identificador
		elif tipo_error == 1:
			pedido_actual.ticket_producto = pedido_actual.nombre_producto
			pedido_actual.ticket_peso_kg = pedido_actual.peso_kg + 5.0 # Peso falso
			pedido_actual.ticket_codigo_identificador = pedido_actual.codigo_identificador
		else:
			pedido_actual.ticket_producto = pedido_actual.nombre_producto
			pedido_actual.ticket_peso_kg = pedido_actual.peso_kg
			pedido_actual.ticket_codigo_identificador = "RF-000 XX" # Código falso
	else:
		# Coinciden exactamente
		pedido_actual.ticket_producto = pedido_actual.nombre_producto
		pedido_actual.ticket_peso_kg = pedido_actual.peso_kg
		pedido_actual.ticket_codigo_identificador = pedido_actual.codigo_identificador

	# UPDATE la planilla con los datos de esta nueva order
	if planilla_ui:
		planilla_ui.cargar_pedido(pedido_actual)
	
	
