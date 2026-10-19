extends Node3D

# Ref a la instancia de la planilla dentro del CanvasLayer
@onready var planilla_ui: Control = $UIPlanilla/PlanillaUI

#  Precargamos la escena de la caja para poder instanciar news pedidos por código
const CAJA_ESCENA = preload("res://escenas/caja/caja.tscn")

# Listas de control de historial (para que no se repitan los pedidos)
var indices_legales_disponibles: Array[int] = []
var indices_ilegales_disponibles: Array[int] = []

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


func _ready() -> void:
	if indices_legales_disponibles.is_empty() and indices_ilegales_disponibles.is_empty():
		_reiniciar_bolsas_de_objetos() #si ya no hay mas objetos se reinician
	probar_carga_pedido()
	
	$Espacio_Trabajo/CintaTransportadora.registrar_caja($Espacio_Trabajo/caja)
	
	#  Conectamos la señal del EventBus para que al terminar de salir una caja, se pida la siguiente
	EventBus.siguiente_pedido_solicitado.connect(_on_siguiente_pedido_solicitado)

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



func probar_carga_pedido() -> void:
# Crea el primer PedidoInfo usando el sistema de bolsas sin repetición
	var pedido_test = PedidoInfo.new()
	pedido_test.es_ilegal = randf() < 0.3
	
	if pedido_test.es_ilegal:
		var idx = _obtener_indice_ilegal_unico()
		pedido_test.nombre_producto = nombres_ilegales[idx]
		pedido_test.objeto_escena = mallas_ilegales[idx]
	else:
		var idx = _obtener_indice_legal_unico()
		pedido_test.nombre_producto = nombres_legales[idx]
		pedido_test.objeto_escena = mallas_legales[idx]
		
	pedido_test.peso_kg = snappedf(randf_range(10.0, 30.0), 0.001)
	pedido_test.codigo_identificador = "RF-396 VY"

	# Asignam el recurso a la caja inicial que ya está en la escena
	if has_node("Espacio_Trabajo/caja/caja_interactiva"):
		$Espacio_Trabajo/caja/caja_interactiva.info = pedido_test
		
	# Lo envía a la planilla para que actualice sus datos
	if planilla_ui:
		planilla_ui.cargar_pedido(pedido_test)
	else:
		print("Error: No se encontró la PlanillaUI en la ruta especificada.")
func _on_boton_tienda_pressed() -> void:
	$CanvasLayer/tienda.show()

# Func que crea la siguiente caja y genera datos aleatorios
func _on_siguiente_pedido_solicitado() -> void:
	var nueva_caja = CAJA_ESCENA.instantiate()
	var pedido_nuevo = PedidoInfo.new()
	
	# 30% de probabilidad de que sea un pedido ilegal
	pedido_nuevo.es_ilegal = randf() < 0.3
	
	if pedido_nuevo.es_ilegal:
		var idx = _obtener_indice_ilegal_unico()
		pedido_nuevo.nombre_producto = nombres_ilegales[idx]
		pedido_nuevo.objeto_escena = mallas_ilegales[idx]
	else:
		var idx = _obtener_indice_legal_unico()
		pedido_nuevo.nombre_producto = nombres_legales[idx]
		pedido_nuevo.objeto_escena = mallas_legales[idx]
	
	# Valores aleatorios de peso y código
	pedido_nuevo.peso_kg = snappedf(randf_range(10.0, 30.0), 0.001)
	pedido_nuevo.codigo_identificador = "RF-" + str(randi_range(100, 999)) + " VY"
	
	# Inyectamos el recurso PedidoInfo al nodo caja_interactiva
	nueva_caja.get_node("caja_interactiva").info = pedido_nuevo
	$Espacio_Trabajo.add_child(nueva_caja)
	
	# Actualizamos la planilla UI
	if planilla_ui:
		planilla_ui.cargar_pedido(pedido_nuevo)
	
	# Registramos la nueva caja en la cinta transportadora
	$Espacio_Trabajo/CintaTransportadora.registrar_caja(nueva_caja)
