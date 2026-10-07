class_name Inventario
extends Control

## Inventario de herramientas de la escena principal.
##
## Muestra las herramientas disponibles (las mismas de la tienda) con su
## representación visual, su nivel de mejora y un cartel descriptivo.
## Permite SELECCIONAR una herramienta.
##
## NOTA: Es un inventario AUTÓNOMO. No está conectado a la tienda ni a la
## lógica del juego. El nivel de cada herramienta se puede cambiar en tiempo
## de ejecución con set_nivel(id, nivel) cuando se quiera conectar más adelante.

const ORDEN: Array[String] = ["escaner", "cuter", "balanza", "energizante"]

@export var escaner_nivel: int = 1
@export var cuter_nivel: int = 1
@export var balanza_nivel: int = 1
@export var energizante_nivel: int = 1

@onready var cartel: PanelContainer = $Cartel
@onready var lbl_nombre: Label = $Cartel/VBoxContainer/Nombre
@onready var lbl_nivel: Label = $Cartel/VBoxContainer/Nivel
@onready var lbl_descripcion: Label = $Cartel/VBoxContainer/Descripcion
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
			"descripcion": "Dispositivo de inspección por rayos X. Revela el contenido interno de los paquetes sin abrirlos.",
			"nivel": escaner_nivel,
		},
		"cuter": {
			"nombre": "Cúter",
			"descripcion": "Permite abrir paquetes para realizar una inspección directa de su interior.",
			"nivel": cuter_nivel,
		},
		"balanza": {
			"nombre": "Balanza",
			"descripcion": "Pesa los paquetes en tiempo real para contrastar su peso real con la planilla.",
			"nivel": balanza_nivel,
		},
		"energizante": {
			"nombre": "Energizante",
			"descripcion": "Bebida de recuperación rápida para mantener el ritmo durante el turno.",
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
			slot.mouse_entered.connect(_on_slot_hover.bind(id))
			_actualizar_badge(slot, id)
	hotbar.mouse_exited.connect(_on_hotbar_mouse_exited)

# --- Selección -------------------------------------------------------------

func seleccionar(id: String) -> void:
	if not herramientas.has(id):
		return
	herramienta_seleccionada = id
	for slot in hotbar.get_children():
		if slot is Button:
			slot.set_pressed_no_signal(slot.get_meta("herramienta_id", "") == id)
	_mostrar_info(id)

func _on_slot_pressed(id: String) -> void:
	seleccionar(id)

func _on_slot_hover(id: String) -> void:
	# Vista previa al pasar el mouse por encima.
	_mostrar_info(id)

func _on_hotbar_mouse_exited() -> void:
	# Al salir, vuelve a mostrar la herramienta seleccionada.
	_mostrar_info(herramienta_seleccionada)

# --- Cartel descriptivo ----------------------------------------------------

func _mostrar_info(id: String) -> void:
	if not herramientas.has(id):
		return
	var datos: Dictionary = herramientas[id]
	lbl_nombre.text = datos["nombre"]
	lbl_nivel.text = _texto_nivel(datos["nivel"])
	lbl_descripcion.text = datos["descripcion"]

func _texto_nivel(nivel: int) -> String:
	return "Nivel " + str(nivel)

func _actualizar_badge(slot: Button, id: String) -> void:
	var badge: Label = slot.get_node_or_null("Badge")
	if badge:
		badge.text = _texto_nivel(herramientas[id]["nivel"])

# --- API pública (lista para conectar a futuro) ----------------------------

func set_nivel(id: String, nivel: int) -> void:
	if not herramientas.has(id):
		return
	herramientas[id]["nivel"] = nivel
	for slot in hotbar.get_children():
		if slot is Button and slot.get_meta("herramienta_id", "") == id:
			_actualizar_badge(slot, id)
	if herramienta_seleccionada == id:
		_mostrar_info(id)

func get_herramienta_seleccionada() -> String:
	return herramienta_seleccionada