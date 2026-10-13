extends Node3D

# Ref a la instancia de la planilla dentro del CanvasLayer
@onready var planilla_ui: Control = $UIPlanilla/PlanillaUI

#  Precargamos la escena de la caja para poder instanciar news pedidos por código
const CAJA_ESCENA = preload("res://escenas/caja/caja.tscn")

func _ready() -> void:
	probar_carga_pedido()
	
	$Espacio_Trabajo/CintaTransportadora.registrar_caja($Espacio_Trabajo/caja)
	
	#  Conectamos la señal del EventBus para que al terminar de salir una caja, se pida la siguiente
	EventBus.siguiente_pedido_solicitado.connect(_on_siguiente_pedido_solicitado)

func probar_carga_pedido() -> void:
# crea un Pedidoinfo de prueba
	var pedido_test = PedidoInfo.new()
	pedido_test.nombre_producto = "Alfajor"
	pedido_test.peso_kg = 20.546
	pedido_test.codigo_identificador = "RF-396 VY"
	pedido_test.es_ilegal = false

#lo envia a la planilla para que actualice sus datos
	if planilla_ui:
		planilla_ui.cargar_pedido(pedido_test)
	else:
		print("Error: No se encontró la PlanillaUI en la ruta especificada.")

func _on_boton_tienda_pressed() -> void:
	$CanvasLayer/tienda.show()

# Func que crea la siguiente caja y genera datos aleatorios
func _on_siguiente_pedido_solicitado() -> void:
	# instanciamos una nueva caja a partir de la escena precargada
	var nueva_caja = CAJA_ESCENA.instantiate()

	#add como hija dentro del nodo contenedor (Espacio_Trabajo)
	$Espacio_Trabajo.add_child(nueva_caja)
	
	#  genera un pedido con datos aleatorios (puedes expandir esto con más productos o lógica)
	var pedido_nuevo = PedidoInfo.new()
	var productos_posibles = ["Alfajor", "Cocaína", "BMO", "Copa", "Microondas"]
	pedido_nuevo.nombre_producto = productos_posibles.pick_random()
	
	# genera un peso aleatorio con 3 decimales 
	pedido_nuevo.peso_kg = snappedf(randf_range(10.0, 30.0), 0.001)
	
	# genera un código aleatorio 
	pedido_nuevo.codigo_identificador = "RF-" + str(randi_range(100, 999)) + " VY"
	pedido_nuevo.es_ilegal = randf() > 0.7 # 30% de probabilidad de que sea ilegal
	#VERIFICAR ESTO DEL PORCENTAJE DE ILEGAL
	
	# UPDATE la planilla con los datos de esta nueva order
	if planilla_ui:
		planilla_ui.cargar_pedido(pedido_nuevo)
	
	# registra la nueva caja en la cinta para que comience su recorrido de entrada
	$Espacio_Trabajo/CintaTransportadora.registrar_caja(nueva_caja)
