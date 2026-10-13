class_name Inventario
extends Control

## Inventario de herramientas de la escena principal.
##
## Muestra las herramientas disponibles como slots seleccionables, con su
## representación visual y un texto corto (nombre + nivel) que aparece como
## tooltip al pasar el mouse por encima.
##
## El inventario escucha al EventBus: cuando la tienda vende una herramienta
## (herramienta_desbloqueada) o una mejora (herramienta_mejorada), el slot se
## actualiza de inmediato. Las herramientas no adquiridas permanecen ocultas
## (nivel 0 = no adquirida).

const ORDEN: Array[String] = ["escaner", "cuter", "balanza", "energizante"]

@export var escaner_nivel: int = 1
@export var cuter_nivel: int = 1
@export var balanza_nivel: int = 0
@export var energizante_nivel: int = 0

@onready var hotbar: HBoxContainer = $Hotbar

var herramientas: Dictionary = {}
var herramienta_seleccionada: String = ""

func _ready() -> void:
	_configurar_datos()
	_conectar_slots()
	_conectar_eventbus()
	_actualizar_todos_los_slots()
	# Por defecto arranca con la primera herramienta disponible seleccionada.
	seleccionar(_primera_disponible())

func _conectar_eventbus() -> void:
	EventBus.herramienta_desbloqueada.connect(_on_herramienta_desbloqueada)
	EventBus.herramienta_mejorada.connect(_on_herramienta_mejorada)

func _configurar_datos() -> void:
	herramientas = {
		"escaner": {
			"nombre": "Escáner",
			"nivel": escaner_nivel,
		},
		"cuter": {
			"nombre": "Cúter",
			"nivel": cuter_nivel,
		},
		"balanza": {
			"nombre": "Balanza",
			"nivel": balanza_nivel,
		},
		"energizante": {
			"nombre": "Energizante",
			"nivel": energizante_nivel,
		},
	}
	# Una herramienta está desbloqueada si ya se posee (nivel > 0).
	for id in herramientas:
		herramientas[id]["desbloqueada"] = herramientas[id]["nivel"] > 0

func _conectar_slots() -> void:
	for slot in hotbar.get_children():
		if slot is Button:
			var id: String = slot.get_meta("herramienta_id", "")
			if id == "":
				continue
			slot.pressed.connect(_on_slot_pressed.bind(id))

func _actualizar_todos_los_slots() -> void:
	for slot in hotbar.get_children():
		if slot is Button:
			var id: String = slot.get_meta("herramienta_id", "")
			if id != "" and herramientas.has(id):
				_actualizar_slot(slot, id)

func _refrescar_slot(id: String) -> void:
	for slot in hotbar.get_children():
		if slot is Button and slot.get_meta("herramienta_id", "") == id:
			_actualizar_slot(slot, id)

# --- Selección -------------------------------------------------------------

func seleccionar(id: String) -> void:
	if not herramientas.has(id) or not herramientas[id]["desbloqueada"]:
		return
	herramienta_seleccionada = id
	for slot in hotbar.get_children():
		if slot is Button:
			slot.set_pressed_no_signal(slot.get_meta("herramienta_id", "") == id)

func _on_slot_pressed(id: String) -> void:
	seleccionar(id)

func _primera_disponible() -> String:
	for id in ORDEN:
		if herramientas.has(id) and herramientas[id]["desbloqueada"]:
			return id
	return ORDEN[0]

# --- Texto corto (badge + tooltip) -----------------------------------------

func _actualizar_slot(slot: Button, id: String) -> void:
	var datos: Dictionary = herramientas[id]
	var desbloqueada: bool = datos["desbloqueada"]
	# Las herramientas no adquiridas no se muestran en la hotbar.
	slot.visible = desbloqueada
	slot.disabled = not desbloqueada

	var badge: Label = slot.get_node_or_null("Badge")
	if not desbloqueada:
		if badge:
			badge.visible = false
		slot.tooltip_text = datos["nombre"] + " (no adquirida)"
		return

	var nivel: int = datos["nivel"]
	var nivel_texto: String = _texto_nivel(nivel)
	if badge:
		badge.text = nivel_texto
	# Texto corto que aparece al pasar el mouse sobre la herramienta.
	slot.tooltip_text = datos["nombre"] + " (" + nivel_texto + ")"

func _texto_nivel(nivel: int) -> String:
	return "Nivel " + str(nivel)

# --- API pública (conectada a la tienda vía EventBus) ----------------------

func _on_herramienta_desbloqueada(id: String) -> void:
	if not herramientas.has(id):
		return
	herramientas[id]["desbloqueada"] = true
	if herramientas[id]["nivel"] <= 0:
		herramientas[id]["nivel"] = 1
	_refrescar_slot(id)

func _on_herramienta_mejorada(id: String, nivel: int) -> void:
	if not herramientas.has(id):
		return
	herramientas[id]["desbloqueada"] = nivel > 0
	herramientas[id]["nivel"] = nivel
	_refrescar_slot(id)

func set_nivel(id: String, nivel: int) -> void:
	if not herramientas.has(id):
		return
	herramientas[id]["nivel"] = nivel
	herramientas[id]["desbloqueada"] = nivel > 0
	_refrescar_slot(id)

func desbloquear(id: String) -> void:
	_on_herramienta_desbloqueada(id)

func get_herramienta_seleccionada() -> String:
	return herramienta_seleccionada
