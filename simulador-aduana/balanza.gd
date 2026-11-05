class_name Balanza
extends Node3D

@onready var area_balanza: Area3D = $AreaBalanza
@onready var label_peso: Label3D = $Label3D

signal peso_detectado(peso_real: float)

var caja_actual: Node3D = null
var peso_en_balanza: float = 0.0

func _ready() -> void:
	if area_balanza:
		area_balanza.body_entered.connect(_on_caja_entrada)
		area_balanza.body_exited.connect(_on_caja_salida)
	
	# Escucha cuándo se selecciona una herramienta en la hotbar
	EventBus.herramienta_seleccionada.connect(_on_herramienta_seleccionada)
	
	# Arranca oculta y desactivada por defecto
	visible = false
	if label_peso:
		label_peso.text = ""

func _on_herramienta_seleccionada(id: String) -> void:
	# La balanza solo se hace visible si el jugador selecciona su slot en el inventario
	visible = (id == "balanza")
	if not visible:
		caja_actual = null
		if label_peso:
			label_peso.text = ""

func _on_caja_entrada(body: Node3D) -> void:
	if not visible:
		return

	var script_caja = body.get_node_or_null("caja_interactiva")
	if script_caja or body.is_in_group("cajas"):
		# Validar si quedan usos disponibles en el día antes de permitir pesar
		if GameManager.obtener_usos_restantes("balanza") == 0:
			print("¡Balanza sin usos restantes hoy!")
			return

		caja_actual = body
		calcular_peso_total()
		
		# Consumir un uso de la balanza a través del GameManager (descuenta en el HUD)
		GameManager.consumir_uso_herramienta("balanza")

func _on_caja_salida(body: Node3D) -> void:
	if body == caja_actual:
		caja_actual = null
		if label_peso:
			label_peso.text = ""
		print("Balanza vacía.")

func calcular_peso_total() -> void:
	if not is_instance_valid(caja_actual) or not visible:
		return

	var script_caja = caja_actual.get_node_or_null("caja_interactiva")
	if script_caja and "pedido_asociado" in script_caja and script_caja.pedido_asociado:
		var pedido = script_caja.pedido_asociado
		peso_en_balanza = pedido.peso_kg

		# Muestra el peso real en el Label3D flotante
		if label_peso:
			label_peso.text = "%.2f kg" % peso_en_balanza

		emit_signal("peso_detectado", peso_en_balanza)
		print("¡Peso real medido en balanza: ", peso_en_balanza, " kg!")
	else:
		if label_peso:
			label_peso.text = "Error"
		print("La caja detectada no tiene un PedidoInfo asociado.")
