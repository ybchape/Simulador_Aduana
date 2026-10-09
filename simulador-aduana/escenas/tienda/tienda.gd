extends Control

## Tienda de herramientas.
##
## La billetera del jugador es compartida a través de EventBus.billetera. Cada
## producto descuenta su precio exacto, y la compra/mejora se comunica al
## inventario emitiendo EventBus.herramienta_desbloqueada /
## EventBus.herramienta_mejorada. Los botones se deshabilitan en vivo cuando el
## saldo no alcanza para el producto.

const NIVEL_MAXIMO: int = 2

# id -> datos del producto. "inicial" es el nivel con el que arranca la partida
# (0 = no adquirida).
const CATALOGO: Dictionary = {
	"escaner": {"nombre": "Escáner", "precio_compra": 450, "precio_mejora": 300, "inicial": 1},
	"cuter": {"nombre": "Cúter", "precio_compra": 450, "precio_mejora": 300, "inicial": 1},
	"balanza": {"nombre": "Balanza", "precio_compra": 450, "precio_mejora": 300, "inicial": 0},
	"energizante": {"nombre": "Energizante", "precio_compra": 150, "precio_mejora": 300, "inicial": 0},
}

const RUTAS_PANEL: Dictionary = {
	"escaner": "ScrollContainer/VBoxContainer/PanelEscaner/HBoxContainer",
	"cuter": "ScrollContainer/VBoxContainer/PanelCuter/HBoxContainer",
	"balanza": "ScrollContainer/VBoxContainer/PanelBalanza/HBoxContainer",
	"energizante": "ScrollContainer/VBoxContainer/PanelEnergizante/HBoxContainer",
}

const RUTAS_LABEL: Dictionary = {
	"escaner": "ScrollContainer/VBoxContainer/PanelEscaner/HBoxContainer/VBoxContainer/nivel_escaner",
	"cuter": "ScrollContainer/VBoxContainer/PanelCuter/HBoxContainer/VBoxContainer/nivel_cutar",
	"balanza": "ScrollContainer/VBoxContainer/PanelBalanza/HBoxContainer/VBoxContainer/nivel_balanza",
	"energizante": "ScrollContainer/VBoxContainer/PanelEnergizante/HBoxContainer/VBoxContainer/Nivel_energizante",
}

@onready var texto_dinero: Label = $Label

# Estado por producto: id -> nivel (0 = no adquirida).
var niveles: Dictionary = {}
# Referencias cacheadas: id -> { "comprar": Button, "mejorar": Button }.
var botones: Dictionary = {}
# Referencias a las etiquetas de nivel: id -> Label.
var etiquetas: Dictionary = {}

func _ready() -> void:
	_inicializar_estado()
	_cachear_nodos()
	_conectar_botones()
	EventBus.dinero_cambiado.connect(_on_dinero_cambiado)
	_refrescar_todo()

func _inicializar_estado() -> void:
	for id in CATALOGO:
		niveles[id] = CATALOGO[id]["inicial"]

func _cachear_nodos() -> void:
	for id in CATALOGO:
		var raiz: String = RUTAS_PANEL[id] + "/VBoxContainer2"
		botones[id] = {
			"comprar": get_node_or_null(raiz + "/BtnComprar"),
			"mejorar": get_node_or_null(raiz + "/BtnMejorar"),
		}
		etiquetas[id] = get_node_or_null(RUTAS_LABEL[id])

func _conectar_botones() -> void:
	for id in CATALOGO:
		var par: Dictionary = botones[id]
		if par["comprar"]:
			par["comprar"].pressed.connect(_on_comprar_pressed.bind(id))
		if par["mejorar"]:
			par["mejorar"].pressed.connect(_on_mejorar_pressed.bind(id))

func _on_dinero_cambiado(_nuevo_saldo: float) -> void:
	_refrescar_todo()

func _on_comprar_pressed(id: String) -> void:
	_intentar_transaccion(id, true)

func _on_mejorar_pressed(id: String) -> void:
	_intentar_transaccion(id, false)

func _intentar_transaccion(id: String, es_compra: bool) -> void:
	if not niveles.has(id):
		return

	var nivel: int = niveles[id]
	if nivel >= NIVEL_MAXIMO:
		return

	var precio: int = CATALOGO[id]["precio_compra"] if nivel == 0 else CATALOGO[id]["precio_mejora"]

	# Descuenta el precio exacto. Si no alcanza, no se hace nada.
	if not EventBus.gastar_dinero(precio):
		_refrescar_todo()
		return

	if es_compra and nivel == 0:
		niveles[id] = 1
		EventBus.herramienta_desbloqueada.emit(id)
	else:
		niveles[id] = nivel + 1
		EventBus.herramienta_mejorada.emit(id, niveles[id])

	_refrescar_todo()

# --- Refresco de la interfaz -----------------------------------------------

func _refrescar_todo() -> void:
	texto_dinero.text = "Dinero disponible: $" + str(int(EventBus.billetera))
	for id in CATALOGO:
		_refrescar_producto(id)

func _refrescar_producto(id: String) -> void:
	var nivel: int = niveles[id]
	var precio_compra: int = CATALOGO[id]["precio_compra"]
	var precio_mejora: int = CATALOGO[id]["precio_mejora"]
	var par: Dictionary = botones[id]
	var btn_comprar: Button = par["comprar"]
	var btn_mejorar: Button = par["mejorar"]
	var label_nivel: Label = etiquetas[id]

	if label_nivel:
		label_nivel.text = "No adquirida" if nivel <= 0 else "Nivel " + str(nivel)

	if nivel <= 0:
		# No adquirida: se ofrece comprarla.
		if btn_comprar:
			btn_comprar.visible = true
			btn_comprar.text = "Comprar: $" + str(precio_compra)
			btn_comprar.disabled = EventBus.billetera < precio_compra
		if btn_mejorar:
			btn_mejorar.visible = false
	elif nivel < NIVEL_MAXIMO:
		# Adquirida, disponible para mejorar.
		if btn_comprar:
			btn_comprar.visible = false
		if btn_mejorar:
			btn_mejorar.visible = true
			btn_mejorar.text = "Mejorar: $" + str(precio_mejora)
			btn_mejorar.disabled = EventBus.billetera < precio_mejora
	else:
		# Nivel máximo alcanzado.
		if btn_comprar:
			btn_comprar.visible = false
		if btn_mejorar:
			btn_mejorar.visible = true
			btn_mejorar.text = "Nivel máximo"
			btn_mejorar.disabled = true

func _on_button_cerrar_pressed() -> void:
	hide()
