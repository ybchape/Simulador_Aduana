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
	probar_carga_pedido()

	# genera el pedido para la primera caja que ya está en la escena
	#_generar_y_cargar_nuevo_pedido()

	# Registra la caja inicial en la cinta transportadora.
	var caja_inicial: Node3D = $Espacio_Trabajo/caja
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


# Prepara los datos del primer pedido y los carga en la caja que ya existe en la escena.
func probar_carga_pedido() -> void:
	_generar_y_cargar_nuevo_pedido()
	var caja_inicial: Node = get_node_or_null("Espacio_Trabajo/caja/caja_interactiva")
	if caja_inicial and caja_inicial.has_method("inicializar_caja"):
		caja_inicial.inicializar_caja(pedido_actual)

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

# Crea y registra la siguiente caja cuando la anterior termina de salir de la cinta.
func _on_siguiente_pedido_solicitado() -> void:
	var nueva_caja: Node3D = CAJA_ESCENA.instantiate()
	$Espacio_Trabajo.add_child(nueva_caja)
	_generar_y_cargar_nuevo_pedido()

	# Busca el controlador dentro de la caja recién instanciada para asignarle el pedido.
	var script_caja: Node = nueva_caja.get_node_or_null("caja_interactiva")
	if script_caja and script_caja.has_method("inicializar_caja"):
		script_caja.inicializar_caja(pedido_actual)
	else:
		push_error("No se encontró el nodo caja_interactiva en la nueva caja.")
		return

	$Espacio_Trabajo/CintaTransportadora.registrar_caja(nueva_caja)


# Genera los datos reales y los datos impresos en el ticket para un pedido aleatorio.
func _generar_y_cargar_nuevo_pedido() -> void:
	pedido_actual = PedidoInfo.new()
	# Cada paquete tiene un 30 % de probabilidad de ser ilegal.
	pedido_actual.es_ilegal = randf() < 0.3

	# Selecciona un objeto de la lista correspondiente sin repetir hasta agotar la bolsa.
	if pedido_actual.es_ilegal:
		var indice_ilegal: int = _obtener_indice_ilegal_unico()
		pedido_actual.nombre_producto = nombres_ilegales[indice_ilegal]
		pedido_actual.objeto_escena = mallas_ilegales[indice_ilegal]
	else:
		var indice_legal: int = _obtener_indice_legal_unico()
		pedido_actual.nombre_producto = nombres_legales[indice_legal]
		pedido_actual.objeto_escena = mallas_legales[indice_legal]

	pedido_actual.peso_kg = snappedf(randf_range(10.0, 30.0), 0.001)
	pedido_actual.codigo_identificador = "RF-" + str(randi_range(100, 999)) + " VY"

	# En paquetes ilegales, el ticket muestra una discrepancia aleatoria en un solo dato.
	if pedido_actual.es_ilegal:
		var tipo_error: int = randi() % 3
		# Caso 0: producto declarado falso o prohibido.
		if tipo_error == 0:
			pedido_actual.ticket_producto = "Producto Prohibido"
			pedido_actual.ticket_peso_kg = pedido_actual.peso_kg
			pedido_actual.ticket_codigo_identificador = pedido_actual.codigo_identificador
		# Caso 1: peso declarado mayor que el peso real.
		elif tipo_error == 1:
			pedido_actual.ticket_producto = pedido_actual.nombre_producto
			pedido_actual.ticket_peso_kg = pedido_actual.peso_kg + 5.0
			pedido_actual.ticket_codigo_identificador = pedido_actual.codigo_identificador
		# Caso 2: código identificador falso.
		else:
			pedido_actual.ticket_producto = pedido_actual.nombre_producto
			pedido_actual.ticket_peso_kg = pedido_actual.peso_kg
			pedido_actual.ticket_codigo_identificador = "RF-000 XX"
	else:
		pedido_actual.ticket_producto = pedido_actual.nombre_producto
		pedido_actual.ticket_peso_kg = pedido_actual.peso_kg
		pedido_actual.ticket_codigo_identificador = pedido_actual.codigo_identificador

	# Actualiza la planilla visible con los datos del pedido recién generado.
	if planilla_ui:
		planilla_ui.cargar_pedido(pedido_actual)
