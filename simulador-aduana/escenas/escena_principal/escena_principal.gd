extends Node3D

# Referencia a la instancia de la planilla dentro del CanvasLayer
@onready var planilla_ui: Control = $UIPlanilla/PlanillaUI

func _ready() -> void:
	probar_carga_pedido()

func probar_carga_pedido() -> void:
# crea un Pedidoinfo de prueba 
	var pedido_test = PedidoInfo.new()
	pedido_test.nombre_producto = "Alfajor"
	pedido_test.peso_kg = 20.546
	pedido_test.codigo_identificador = "RF-396 VY"
	pedido_test.es_ilegal = false

# lo envia a la planilla para que actualice sus datos
	if planilla_ui:
		planilla_ui.cargar_pedido(pedido_test)
	else:
		print("Error: No se encontró la PlanillaUI en la ruta especificada.")
