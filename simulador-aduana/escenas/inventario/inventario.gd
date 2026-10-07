class_name Inventario
extends Control

## Inventario de herramientas de la escena principal.
##
## Muestra las herramientas disponibles (las mismas de la tienda) como slots
## seleccionables, con su representación visual y un texto corto (nombre + nivel)
## que aparece como tooltip al pasar el mouse por encima.
##
## NOTA: Es un inventario AUTÓNOMO. No está conectado a la tienda ni a la
## lógica del juego. El nivel de cada herramienta se puede cambiar en tiempo
## de ejecución con set_nivel(id, nivel) cuando se quiera conectar más adelante.

const ORDEN: Array[String] = ["escaner", "cuter", "balanza", "energizante"]

@export var escaner_nivel: int = 1
@export var cuter_nivel: int = 1
@export var balanza_nivel: int = 1
@export var energizante_nivel: int = 1

@onready var hotbar: HBoxContainer = $Hotbar

var herramientas: Dictionary = {}
var herramienta_seleccionada: String = ""

func _ready() -> void:
	_configurar_datos()
	_conectar_slots()
	# Por defecto arranca con la primera herramienta seleccionada.
	seleccionar(ORDEN[0])

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

func _conectar_slots() -> void:
	for slot in hotbar.get_children():
		if slot is Button:
			var id: String = slot.get_meta("herramienta_id", "")
			if id == "":
				continue
			slot.pressed.connect(_on_slot_pressed.bind(id))
			_actualizar_slot(slot, id)

# --- Selección -------------------------------------------------------------

func seleccionar(id: String) -> void:
	if not herramientas.has(id):
		return
	herramienta_seleccionada = id
	for slot in hotbar.get_children():
		if slot is Button:
			slot.set_pressed_no_signal(slot.get_meta("herramienta_id", "") == id)

func _on_slot_pressed(id: String) -> void:
	seleccionar(id)

# --- Texto corto (badge + tooltip) -----------------------------------------

func _actualizar_slot(slot: Button, id: String) -> void:
	var datos: Dictionary = herramientas[id]
	var nivel: String = _texto_nivel(datos["nivel"])
	var badge: Label = slot.get_node_or_null("Badge")
	if badge:
		badge.text = nivel
	# Texto corto que aparece al pasar el mouse sobre la herramienta.
	slot.tooltip_text = datos["nombre"] + " (" + nivel + ")"

func _texto_nivel(nivel: int) -> String:
	return "Nivel " + str(nivel)

# --- API pública (lista para conectar a futuro) ----------------------------

func set_nivel(id: String, nivel: int) -> void:
	if not herramientas.has(id):
		return
	herramientas[id]["nivel"] = nivel
	for slot in hotbar.get_children():
		if slot is Button and slot.get_meta("herramienta_id", "") == id:
			_actualizar_slot(slot, id)

func get_herramienta_seleccionada() -> String:
	return herramienta_seleccionada
