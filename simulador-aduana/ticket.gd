extends Control

@onready var lbl_producto: Label = $Fondo/MarginContainer/VBoxContainer/LblProducto
@onready var lbl_peso: Label = $Fondo/MarginContainer/VBoxContainer/LblPeso
@onready var lbl_codigo: Label = $Fondo/MarginContainer/VBoxContainer/LblCodigo

# Probabilidad de que un pedido ilegal venga con ticket falso
@export_range(0.0, 1.0) var probabilidad_alteracion: float = 0.8

func cargar_ticket(datos: PedidoInfo) -> void:
	if datos == null:
		print("Advertencia: No se recibieron datos de pedido para el ticket.")
		return

	# Si es ilegal y aún no se generó una falsificación previa para este pedido, la creamos
	if datos.es_ilegal and datos.ticket_producto == "" and randf() < probabilidad_alteracion:
		_generar_falsificacion_azar(datos)

	# Si no se falsificó (o si el pedido es legal), mostramos los valores correctos
	var prod = datos.ticket_producto if datos.ticket_producto != "" else datos.nombre_producto
	var peso = datos.ticket_peso_kg if datos.ticket_peso_kg > 0.0 else datos.peso_kg
	var cod = datos.ticket_codigo_identificador if datos.ticket_codigo_identificador != "" else datos.codigo_identificador

	lbl_producto.text = "Producto: " + prod
	lbl_peso.text = "Peso: " + str(peso) + " kg"
	lbl_codigo.text = "Código: " + cod

func _generar_falsificacion_azar(datos: PedidoInfo) -> void:
	# Elegimos un tipo de discrepancia al azar (0: Producto, 1: Peso, 2: Código)
	var tipo_error = randi() % 3
	
	match tipo_error:
		0:
			# Cambia el nombre por una variante o error tipográfico
			datos.ticket_producto = datos.nombre_producto + " (Declaración Varia)"
		1:
			# Modifica el peso agregando o quitando entre 1.5kg y 4.0kg
			var diferencia = randf_range(1.5, 4.0) * (-1.0 if randf() > 0.5 else 1.0)
			var peso_falso = datos.peso_kg + diferencia
			datos.ticket_peso_kg = snapped(max(0.5, peso_falso), 0.1)
		2:
			# Altera los últimos 3 caracteres del código
			if datos.codigo_identificador.length() >= 3:
				var base = datos.codigo_identificador.substr(0, datos.codigo_identificador.length() - 3)
				datos.ticket_codigo_identificador = base + str(randi_range(100, 999))
			else:
				datos.ticket_codigo_identificador = "ERR-999"
