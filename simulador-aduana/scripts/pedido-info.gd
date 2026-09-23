class_name PedidoInfo
extends Resource

@export var nombre_producto: String = ""
@export var peso_kg: float = 0.0
@export var codigo_identificador: String = ""
@export var es_ilegal: bool = false

# Datos falsificados para el ticket de la caja (si la caja inconsistencias)
@export var ticket_producto: String = ""
@export var ticket_peso_kg: float = 0.0
@export var ticket_codigo_identificador: String = ""
