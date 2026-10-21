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
var pedido_en_zona: bool = false

func _ready() -> void:
	# La caja localiza el inventario por grupo al recibir el clic 3D.
	add_to_group("inventario")
	_configurar_datos()
	_conectar_slots()
	_conectar_eventbus()
	_actualizar_todos_los_slots()
	# Por defecto arranca con la primera herramienta disponible seleccionada.
	seleccionar(_primera_disponible())

func _conectar_eventbus() -> void:
	EventBus.herramienta_desbloqueada.connect(_on_herramienta_desbloqueada)
	EventBus.herramienta_mejorada.connect(_on_herramienta_mejorada)
	EventBus.pedido_en_zona.connect(_on_pedido_en_zona)

func _on_pedido_en_zona(hay_pedido: bool) -> void:
	pedido_en_zona = hay_pedido
	if not hay_pedido and herramienta_seleccionada in ["escaner", "cuter"]:
		salir_del_cuter()

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

	# Reconstruir las herramientas compradas/mejoradas desde el estado persistente
	# después de cambiar de día (la escena se vuelve a cargar).
	for id in ORDEN:
		var nivel_guardado: int = 1 if GameManager.mejoras_compradas.has(id + "_obtenido") else 0
		if id in ["escaner", "cuter"]:
			nivel_guardado = 1
		if GameManager.mejoras_compradas.has(id + "_lvl2"):
			nivel_guardado = 2
		if nivel_guardado > 0:
			herramientas[id]["nivel"] = nivel_guardado
			herramientas[id]["desbloqueada"] = true

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
	if id in ["escaner", "cuter"] and not _esta_pedido_detenido():
		return
	if _obtener_caja_abierta() != null:
		return
	if not herramientas.has(id) or not herramientas[id]["desbloqueada"]:
		return
	herramienta_seleccionada = id
	for slot in hotbar.get_children():
		if slot is Button:
			slot.set_pressed_no_signal(slot.get_meta("herramienta_id", "") == id)

# Usa el estado real de la cinta y no el Area3D, que puede fallar o dispararse tarde.
func _esta_pedido_detenido() -> bool:
	var escena_actual: Node = get_tree().current_scene
	var cinta: Node = escena_actual.get_node_or_null("Espacio_Trabajo/CintaTransportadora") if escena_actual else null
	if cinta == null:
		return false
	var caja_actual: Node = cinta.get("caja_actual") as Node
	var estado_cinta: String = cinta.get("estado") as String
	return estado_cinta == "INSPECCIONANDO" and caja_actual != null

func _obtener_caja_interactiva_actual() -> Node:
	var escena_actual: Node = get_tree().current_scene
	var cinta: Node = escena_actual.get_node_or_null("Espacio_Trabajo/CintaTransportadora") if escena_actual else null
	if cinta == null:
		return null
	var caja: Node = cinta.get("caja_actual") as Node
	if caja == null:
		return null
	return caja.get_node_or_null("caja_interactiva")

func _on_slot_pressed(id: String) -> void:
	var caja_abierta: Node = _obtener_caja_abierta()
	if caja_abierta != null:
		return
	seleccionar(id)

# Encuentra la caja del pedido vigente, haya o no entrado aún en inspección.
func _obtener_caja_abierta() -> Node:
	var interactiva: Node = _obtener_caja_interactiva_actual()
	return interactiva if interactiva and interactiva.get("caja_abierta") else null

# Escape también permite salir del modo de inspección.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		var caja_abierta: Node = _obtener_caja_abierta()
		if caja_abierta != null:
			caja_abierta.cerrar_caja()
			salir_del_cuter()
			get_viewport().set_input_as_handled()

# Se invoca cuando la caja se cierra para quitar la selección del Cúter.
func salir_del_cuter() -> void:
	herramienta_seleccionada = ""
	for slot in hotbar.get_children():
		if slot is Button:
			slot.set_pressed_no_signal(false)
	var pantalla_escaner: Node = get_tree().current_scene.get_node_or_null("PantallaEscaner") if get_tree().current_scene else null
	if pantalla_escaner and pantalla_escaner.has_method("ocultar"):
		pantalla_escaner.ocultar()

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
