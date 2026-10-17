extends Control

@onready var lbl_producto: Label = $Fondo/MarginContainer/VBoxContainer/LblProducto
@onready var lbl_peso: Label = $Fondo/MarginContainer/VBoxContainer/LblPeso
@onready var lbl_codigo: Label = $Fondo/MarginContainer/VBoxContainer/LblCodigo


# func para mostrar el ticket con los datos específicos del manifiesto/ticket de la caja
func cargar_ticket(datos: PedidoInfo) -> void:
	if datos == null:
		return

	lbl_producto.text = "Producto: " + datos.ticket_producto
	lbl_peso.text = "Peso: " + str(datos.ticket_peso_kg) + " kg"
	lbl_codigo.text = "Código: " + datos.ticket_codigo_identificador
