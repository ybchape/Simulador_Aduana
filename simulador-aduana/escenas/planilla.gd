extends Control

@onready var lbl_producto: Label = $MarginContainer/VBoxContainer/LblProducto
@onready var lbl_peso: Label = $MarginContainer/VBoxContainer/LblPeso
@onready var lbl_codigo: Label = $MarginContainer/VBoxContainer/LblCodigo

# función principal para alimentar la planilla con un pedido info func
func cargar_pedido(datos: PedidoInfo) -> void:
	if datos == null:
		print("Advertencia: No se recibieron datos de pedido.")
		return

	lbl_producto.text = "Producto: " + datos.nombre_producto
	lbl_peso.text = "Peso: " + str(datos.peso_kg) + " kg"
	lbl_codigo.text = "Código: " + datos.codigo_identificadorextends
