class_name HerramientaEnEscena
extends Node3D

const ESCENA_BALANZA = preload("res://balanza.tscn")

@export var modelos: Dictionary = {}
# vacio para que empiece sin ninguna herramienta en la mano
@export var herramienta_por_defecto: String = ""

var _id_mostrado: String = ""
var _instancia: Node3D = null

func _ready() -> void:
	modelos["balanza"] = ESCENA_BALANZA

	if not EventBus.herramienta_seleccionada.is_connected(_on_herramienta_seleccionada):
		EventBus.herramienta_seleccionada.connect(_on_herramienta_seleccionada)
	
	# escucha cuando un pedido se acepta o se deniega para quitar la herramienta
	if EventBus.has_signal("pedido_procesado") and not EventBus.pedido_procesado.is_connected(_on_pedido_procesado):
		EventBus.pedido_procesado.connect(_on_pedido_procesado)
	elif EventBus.has_signal("caja_procesada") and not EventBus.caja_procesada.is_connected(_on_pedido_procesado):
		EventBus.caja_procesada.connect(_on_pedido_procesado)

	if not herramienta_por_defecto.is_empty():
		_mostrar(herramienta_por_defecto)
	else:
		_limpiar_instancia()

# func que limpia la herramienta y deselecciona el slot 
func _on_pedido_procesado(_status = null) -> void:
	_limpiar_instancia()
	#avisa al inventario que no hay herramienta seleccionada para apagar el borde del slot
	EventBus.herramienta_seleccionada.emit("")

func _on_herramienta_seleccionada(id: String) -> void:
	if id.is_empty():
		_limpiar_instancia()
	else:
		_mostrar(id)

func _limpiar_instancia() -> void:
	_id_mostrado = ""
	if is_instance_valid(_instancia):
		_instancia.queue_free()
		_instancia = null

func _mostrar(id: String) -> void:
	print("Intentando mostrar herramienta: ", id)
	if id == _id_mostrado and is_instance_valid(_instancia):
		print("La herramienta ya estaba mostrándose.")
		return
	_limpiar_instancia()
	_id_mostrado = id
	var escena: PackedScene = modelos.get(id, null) as PackedScene
	if escena == null:
		print("¡Error! No se encontró la escena en el diccionario para el id: ", id)
		return
	_instancia = escena.instantiate() as Node3D
	add_child(_instancia)
	print("¡Herramienta instanciada con éxito en la escena!")
