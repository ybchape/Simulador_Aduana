class_name Inventario
extends Control

## Inventario de herramientas de la escena principal.
## Muestra las herramientas disponibles como slots seleccionables, con su
## representación visual y un texto corto (nombre + nivel) que aparece como
## tooltip al pasar el mouse por encima.

## El inventario escucha al EventBus: cuando la tienda vende una herramienta
## (herramienta_desbloqueada) o una mejora (herramienta_mejorada), el slot se
## actualiza de inmediato. Las herramientas no adquiridas permanecen ocultas
## (nivel 0 = no adquirida).

## También refleja el estado de uso de cada herramienta (usos restantes del día
## y enfriamiento tras cada uso, gestionados en GameManager). Mientras una
## herramienta está en enfriamiento o agotada, no se puede activar.

const ORDEN: Array[String] = ["escaner", "cuter", "balanza", "energizante"]
const DURACION_AVISO: float = 2.0

@export var escaner_nivel: int = 1
@export var cuter_nivel: int = 1
@export var balanza_nivel: int = 0
@export var energizante_nivel: int = 0

@onready var hotbar: HBoxContainer = $Hotbar
@onready var aviso: Label = get_node_or_null("Aviso") as Label

var herramientas: Dictionary = {}
var herramienta_seleccionada: String = ""
var pedido_en_zona: bool = false
var _aviso_tiempo: float = 0.0

func _ready() -> void:
	# La caja localiza el inventario por grupo al recibir el clic 3D.
	add_to_group("inventario")
	if aviso:
		aviso.visible = false
	_configurar_datos()
	_conectar_slots()
	_conectar_eventbus()
	_actualizar_todos_los_slots()
	# Por defecto arranca con la primera herramienta disponible seleccionada.
	seleccionar(_primera_disponible())

func _process(delta: float) -> void:
	# Refresca los slots en enfriamiento para mostrar la cuenta atrás en vivo.
	for slot in hotbar.get_children():
		if slot is Button:
			var id: String = slot.get_meta("herramienta_id", "")
			if id != "" and herramientas.has(id) and GameManager.obtener_cooldown_restante(id) > 0.0:
				_actualizar_slot(slot, id)

	# Oculta el aviso cuando expira su tiempo.
	if _aviso_tiempo > 0.0:
		_aviso_tiempo -= delta
		if _aviso_tiempo <= 0.0 and aviso:
			aviso.visible = false

func _conectar_eventbus() -> void:
	EventBus.herramienta_desbloqueada.connect(_on_herramienta_desbloqueada)
	EventBus.herramienta_mejorada.connect(_on_herramienta_mejorada)
	EventBus.pedido_en_zona.connect(_on_pedido_en_zona)
	if not GameManager.herramienta_estado_cambiado.is_connected(_on_herramienta_estado_cambiado):
		GameManager.herramienta_estado_cambiado.connect(_on_herramienta_estado_cambiado)

func _on_pedido_en_zona(hay_pedido: bool) -> void:
	pedido_en_zona = hay_pedido
	if not hay_pedido and herramienta_seleccionada in ["escaner", "cuter"]:
		salir_del_cuter()

func _configurar_datos() -> void:
	# Establecer estado inicial por defecto:
	# - escaner y cuter: nivel 1 y desbloqueados desde el inicio
	# - balanza y energizante: nivel 0 y bloqueados (hay que comprarlos)
	herramientas = {
		"escaner": {"nombre": "Escáner", "nivel": 1, "desbloqueada": true},
		"cuter": {"nombre": "Cúter", "nivel": 1, "desbloqueada": true},
		"balanza": {"nombre": "Balanza", "nivel": 0, "desbloqueada": false},
		"energizante": {"nombre": "Energizante", "nivel": 0, "desbloqueada": false},
	}

	# Verificar mejoras de nivel 2 (e scanner/cuter) usando claves de la tienda
	if GameManager.mejoras_compradas.has("escaner_lvl2"):
		herramientas["escaner"]["nivel"] = 2
	if GameManager.mejoras_compradas.has("cuter_lvl2"):
		herramientas["cuter"]["nivel"] = 2

	# Verificar herramientas compradas usando claves de la tienda
	if GameManager.mejoras_compradas.has("balanza_obtenida"):
		herramientas["balanza"]["nivel"] = 1
		herramientas["balanza"]["desbloqueada"] = true
	if GameManager.mejoras_compradas.has("energizante_obtenido"):
		herramientas["energizante"]["nivel"] = 1
		herramientas["energizante"]["desbloqueada"] = true

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
	# No se puede seleccionar una herramienta sin usos restantes hoy.
	if GameManager.obtener_max_usos(id) >= 0 and GameManager.obtener_usos_restantes(id) <= 0:
		return
	herramienta_seleccionada = id
	for slot in hotbar.get_children():
		if slot is Button:
			slot.set_pressed_no_signal(slot.get_meta("herramienta_id", "") == id)
	# Avisa a la escena principal para que muestre el modelo de esta herramienta.
	EventBus.herramienta_seleccionada.emit(id)

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
	# Avisa a la escena principal de que ya no hay herramienta activa.
	EventBus.herramienta_seleccionada.emit("")
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
	var badge: Label = slot.get_node_or_null("Badge")

	# Las herramientas no adquiridas no se muestran en la hotbar.
	if not desbloqueada:
		slot.visible = false
		slot.disabled = true
		slot.modulate = Color(1, 1, 1, 1)
		if badge:
			badge.visible = false
		slot.tooltip_text = str(datos["nombre"]) + " (no adquirida)"
		return
	slot.visible = true

	var nombre: String = datos["nombre"]
	var nivel: int = datos["nivel"]
	var maximo: int = GameManager.obtener_max_usos(id)
	var restantes: int = GameManager.obtener_usos_restantes(id)
	var cooldown: float = GameManager.obtener_cooldown_restante(id)
	var sin_usos: bool = maximo >= 0 and restantes <= 0

	# Estado de uso en el badge: "r/max", "∞" o la cuenta atrás del enfriamiento.
	if badge:
		badge.visible = true
		if sin_usos:
			badge.text = "0/" + str(maximo)
			badge.modulate = Color(1.0, 0.45, 0.45, 1.0) # rojo = agotada
		elif cooldown > 0.0:
			badge.text = "%.1fs" % cooldown
			badge.modulate = Color(1.0, 0.85, 0.4, 1.0) # ámbar = enfriando
		elif maximo < 0:
			badge.text = "∞"
			badge.modulate = Color(1, 1, 1, 1)
		else:
			badge.text = str(restantes) + "/" + str(maximo)
			badge.modulate = Color(1, 1, 1, 1)

	# Se atenúa mientras enfría; se deshabilita solo cuando no quedan usos hoy.
	slot.disabled = sin_usos
	slot.modulate = Color(1, 1, 1, 0.45) if cooldown > 0.0 else Color(1, 1, 1, 1)

	# Tooltip con nombre, nivel y estado de uso.
	var usos_texto: String = "∞" if maximo < 0 else (str(restantes) + "/" + str(maximo))
	var estado_texto: String = ""
	if sin_usos:
		estado_texto = " — Sin usos hoy"
	elif cooldown > 0.0:
		estado_texto = " — Enfriando %.1fs" % cooldown
	slot.tooltip_text = "%s (Nivel %d) — Usos: %s%s" % [nombre, nivel, usos_texto, estado_texto]

	# Si se agotó estando seleccionada, se quita la selección.
	if sin_usos and herramienta_seleccionada == id:
		salir_del_cuter()

# Muestra un mensaje breve centrado sobre la hotbar.
func mostrar_aviso(texto: String) -> void:
	if aviso == null:
		return
	aviso.text = texto
	aviso.visible = true
	_aviso_tiempo = DURACION_AVISO

func _on_herramienta_estado_cambiado(id: String, _restantes: int, _maximo: int) -> void:
	_refrescar_slot(id)

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
