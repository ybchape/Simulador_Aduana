class_name Balanza
extends Node3D

@onready var area_balanza: Area3D = $AreaBalanza
@onready var label_peso: Label3D = $Label3D # Asegúrate de que el nodo se llame Label3D o ajústalo aquí

signal peso_detectado(peso_real: float)

var caja_actual: Node3D = null
var peso_en_balanza: float = 0.0

func _ready() -> void:
	if area_balanza:
		area_balanza.body_entered.connect(_on_caja_entrada)
		area_balanza.body_exited.connect(_on_caja_salida)
	
	# Al arrancar, el cartel de la balanza empieza vacío
	if label_peso:
		label_peso.text = ""

func _on_caja_entrada(body: Node3D) -> void:
	if not visible:
		return

	var script_caja = body.get_node_or_null("caja_interactiva")
	if script_caja or body.is_in_group("cajas"):
		caja_actual = body
		calcular_peso_total()

func _on_caja_salida(body: Node3D) -> void:
	if body == caja_actual:
		caja_actual = null
		peso_en_balanza = 0.0
		emit_signal("peso_detectado", 0.0)
		
		# Limpiamos el texto cuando la caja se va
		if label_peso:
			label_peso.text = ""
			
		print("Balanza vacía.")

func calcular_peso_total() -> void:
	if not is_instance_valid(caja_actual) or not visible:
		return

	var script_caja = caja_actual.get_node_or_null("caja_interactiva")
	if script_caja and "pedido_asociado" in script_caja and script_caja.pedido_asociado:
		var pedido = script_caja.pedido_asociado
		
		# Obtenemos el peso real desde el recurso del pedido
		peso_en_balanza = pedido.peso_kg
		
		print("¡Peso real medido en balanza: ", peso_en_balanza, " kg!")
		emit_signal("peso_detectado", peso_en_balanza)
		
		# Mostramos el peso en el Label3D flotante con formato de 2 decimales y sufijo kg
		if label_peso:
			label_peso.text = "%.2f kg" % peso_en_balanza
	else:
		if label_peso:
			label_peso.text = "Error"
		print("La caja detectada no tiene un PedidoInfo asociado.")
