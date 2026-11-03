extends Control

@onready var lbl_producto: Label = $Fondo/MarginContainer/VBoxContainer/LblProducto
@onready var lbl_peso: Label = $Fondo/MarginContainer/VBoxContainer/LblPeso
@onready var lbl_codigo: Label = $Fondo/MarginContainer/VBoxContainer/LblCodigo

var datos_pendientes: PedidoInfo = null

func _ready() -> void:
	# Asegura que los textos hagan salto de línea automático si son muy largos
	_configurar_autowrap()
	
	if datos_pendientes != null:
		cargar_ticket(datos_pendientes)

func _configurar_autowrap() -> void:
	for label in [lbl_producto, lbl_peso, lbl_codigo]:
		if label:
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func cargar_ticket(datos: PedidoInfo) -> void:
	if datos == null:
		return

	# Si los nodos gráficos todavía no cargaron, guardamos temporalmente
	if not is_node_ready():
		datos_pendientes = datos
		return
		print("Datos del ticket recibidos Producto: ", datos.ticket_producto)

	lbl_producto.text = "Producto: " + str(datos.ticket_producto)
	lbl_peso.text = "Peso: " + str(datos.ticket_peso_kg) + " kg"
	lbl_codigo.text = "Código: " + str(datos.ticket_codigo_identificador)
