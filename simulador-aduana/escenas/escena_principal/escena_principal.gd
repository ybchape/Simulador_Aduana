extends Node3D

# Ref a la instancia de la planilla dentro del CanvasLayer
@onready var planilla_ui: Control = $UIPlanilla/PlanillaUI

# Precargamos la escena de la caja para poder instanciar news pedidos por código
const CAJA_ESCENA = preload("res://escenas/caja/caja.tscn")

# save el pedido activo actual 
var pedido_actual: PedidoInfo = null

func _ready() -> void:
	EventBus.decision_tomada.connect(_on_decision_tomada)

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
	# instanciamos una nueva caja a partir de la escena precargada
	var nueva_caja = CAJA_ESCENA.instantiate()

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

	$Espacio_Trabajo/CintaTransportadora.registrar_caja(nueva_caja)

	# Si la caja tiene la función para inicializarse con el pedido, se la llama
	#if nueva_caja.has_method("inicializar_caja"):
		#nueva_caja.inicializar_caja(pedido_actual)
	# registra la nueva caja en la cinta para que comience su recorrido de entrada
	#$Espacio_Trabajo/CintaTransportadora.registrar_caja(nueva_caja)#

# generación de datos aleatorios para comparar Planilla con ek Ticket 
func _generar_y_cargar_nuevo_pedido() -> void:
	pedido_actual = PedidoInfo.new()
	var productos_posibles = ["Alfajor", "Cocaína", "BMO", "Copa", "Microondas"]
	
	# Datos reales / Planilla
	pedido_actual.nombre_producto = productos_posibles.pick_random()
	pedido_actual.peso_kg = snappedf(randf_range(10.0, 30.0), 0.001)
	pedido_actual.codigo_identificador = "RF-" + str(randi_range(100, 999)) + " VY"

	# Determinar si el paquete será ilegal (30% de probabilidad)
	pedido_actual.es_ilegal = randf() < 0.3

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
