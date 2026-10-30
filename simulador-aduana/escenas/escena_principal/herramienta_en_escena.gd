class_name HerramientaEnEscena
extends Node3D

## Muestra en la escena principal el modelo 3D de la herramienta que el jugador
## tiene seleccionada en el inventario (por ejemplo, la pistola escáner o el cúter).

## `modelos` mapea el id de la herramienta (el mismo id de inventario.gd:
## "escaner", "cuter", ...) a la escena (.tscn o .glb) que se muestra en la escena.
## Se puede editar desde el inspector o desde código para **cambiar los assets en
## el futuro** sin tocar la lógica.

## Si no hay herramienta seleccionada, se muestra `herramienta_por_defecto`
## (para que el mostrador no quede vacío).

@export var modelos: Dictionary = {}
@export var herramienta_por_defecto: String = "escaner"

# Guarda qué id se está mostrando y la instancia actual, para no reconstruir el
# modelo si no cambió.
var _id_mostrado: String = ""
var _instancia: Node3D = null

func _ready() -> void:
	if not EventBus.herramienta_seleccionada.is_connected(_on_herramienta_seleccionada):
		EventBus.herramienta_seleccionada.connect(_on_herramienta_seleccionada)
	_mostrar(herramienta_por_defecto)

func _on_herramienta_seleccionada(id: String) -> void:
	_mostrar(id if not id.is_empty() else herramienta_por_defecto)

# Cambia el modelo mostrado por el de la herramienta indicada.
func _mostrar(id: String) -> void:
	if id == _id_mostrado and is_instance_valid(_instancia):
		return
	if is_instance_valid(_instancia):
		_instancia.queue_free()
		_instancia = null
	_id_mostrado = id
	var escena: PackedScene = modelos.get(id, null) as PackedScene
	if escena == null:
		return
	_instancia = escena.instantiate() as Node3D
	add_child(_instancia)
