class_name HerramientaEnEscena
extends Node3D

@export var modelos: Dictionary = {}
# Podés dejarlo vacío para que arranque sin ninguna en mano:
@export var herramienta_por_defecto: String = ""

var _id_mostrado: String = ""
var _instancia: Node3D = null

func _ready() -> void:
	if not EventBus.herramienta_seleccionada.is_connected(_on_herramienta_seleccionada):
		EventBus.herramienta_seleccionada.connect(_on_herramienta_seleccionada)
	# Si querés que empiece sin nada en mano:
	if not herramienta_por_defecto.is_empty():
		_mostrar(herramienta_por_defecto)
	else:
		_limpiar_instancia()

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
	if id == _id_mostrado and is_instance_valid(_instancia):
		return
	_limpiar_instancia()
	_id_mostrado = id
	var escena: PackedScene = modelos.get(id, null) as PackedScene
	if escena == null:
		return
	_instancia = escena.instantiate() as Node3D
	add_child(_instancia)
