extends Control

## Tienda conectada a la billetera persistente de GameManager.
## Los identificadores de mejoras se comparten con el inventario y se conservan
## al recargar la escena entre turnos.

const PRECIO_MEJORA_NIVEL_2: int = 300
const PRECIO_COMPRA_BALANZA: int = 450
const PRECIO_COMPRA_ENERGIZANTE: int = 150

@onready var texto_dinero: Label = $Label
@onready var btn_mejorar_escaner: Button = $ScrollContainer/VBoxContainer/PanelEscaner/HBoxContainer/VBoxContainer2/BtnMejorar
@onready var btn_mejorar_cuter: Button = $ScrollContainer/VBoxContainer/PanelCuter/HBoxContainer/VBoxContainer2/BtnMejorar
@onready var btn_comprar_energizante: Button = $ScrollContainer/VBoxContainer/PanelEnergizante/HBoxContainer/VBoxContainer2/BtnComprar
@onready var btn_mejorar_energizante: Button = $ScrollContainer/VBoxContainer/PanelEnergizante/HBoxContainer/VBoxContainer2/BtnMejorar
@onready var btn_comprar_balanza: Button = $ScrollContainer/VBoxContainer/PanelBalanza/HBoxContainer/VBoxContainer2/BtnComprar
@onready var btn_mejorar_balanza: Button = $ScrollContainer/VBoxContainer/PanelBalanza/HBoxContainer/VBoxContainer2/BtnMejorar
@onready var nivel_escaner: Label = $ScrollContainer/VBoxContainer/PanelEscaner/HBoxContainer/VBoxContainer/nivel_escaner
@onready var nivel_cutar: Label = $ScrollContainer/VBoxContainer/PanelCuter/HBoxContainer/VBoxContainer/nivel_cutar
@onready var nivel_balanza: Label = $ScrollContainer/VBoxContainer/PanelBalanza/HBoxContainer/VBoxContainer/nivel_balanza
@onready var nivel_energizante: Label = $ScrollContainer/VBoxContainer/PanelEnergizante/HBoxContainer/VBoxContainer/Nivel_energizante

func _ready() -> void:
	_conectar_botones()
	if not GameManager.dinero_cambiado.is_connected(_on_dinero_cambiado):
		GameManager.dinero_cambiado.connect(_on_dinero_cambiado)
	_refrescar_tienda()

# Conecta cada botón con la compra o mejora específica de su herramienta.
func _conectar_botones() -> void:
	btn_mejorar_escaner.pressed.connect(_comprar_mejora_escaner)
	btn_mejorar_cuter.pressed.connect(_comprar_mejora_cuter)
	btn_comprar_balanza.pressed.connect(_comprar_balanza)
	btn_mejorar_balanza.pressed.connect(_mejorar_balanza)
	btn_comprar_energizante.pressed.connect(_comprar_energizante)
	btn_mejorar_energizante.pressed.connect(_mejorar_energizante)

func _on_dinero_cambiado(_nuevo_saldo: int) -> void:
	_refrescar_tienda()

# Actualiza saldo, niveles, disponibilidad y estados de compra de toda la tienda.
func _refrescar_tienda() -> void:
	texto_dinero.text = "Dinero disponible: $" + str(GameManager.dinero_total)
	_restaurar_estado_compras()
	_refrescar_estado_botones()

# Refleja en los botones las mejoras que ya quedaron guardadas en GameManager.
func _restaurar_estado_compras() -> void:
	var mejoras: Array[String] = GameManager.mejoras_compradas

	if mejoras.has("escaner_lvl2"):
		btn_mejorar_escaner.text = "¡Adquirido!"
		btn_mejorar_escaner.disabled = true
		nivel_escaner.text = "Nivel 2"
	else:
		btn_mejorar_escaner.text = "Mejorar: $" + str(PRECIO_MEJORA_NIVEL_2)
		nivel_escaner.text = "Nivel 1"

	if mejoras.has("cuter_lvl2"):
		btn_mejorar_cuter.text = "¡Adquirido!"
		btn_mejorar_cuter.disabled = true
		nivel_cutar.text = "Nivel 2"
	else:
		btn_mejorar_cuter.text = "Mejorar: $" + str(PRECIO_MEJORA_NIVEL_2)
		nivel_cutar.text = "Nivel 1"

	if mejoras.has("balanza_obtenida"):
		btn_comprar_balanza.visible = false
		btn_comprar_balanza.disabled = true
		btn_mejorar_balanza.visible = true
		nivel_balanza.text = "Nivel 1"
	else:
		btn_comprar_balanza.visible = true
		btn_comprar_balanza.text = "Comprar: $" + str(PRECIO_COMPRA_BALANZA)
		btn_mejorar_balanza.visible = false
		nivel_balanza.text = "No adquirida"

	if mejoras.has("energizante_obtenido"):
		btn_comprar_energizante.visible = false
		btn_comprar_energizante.disabled = true
		btn_mejorar_energizante.visible = true
		nivel_energizante.text = "Nivel 1"
	else:
		btn_comprar_energizante.visible = true
		btn_comprar_energizante.text = "Comprar: $" + str(PRECIO_COMPRA_ENERGIZANTE)
		btn_mejorar_energizante.visible = false
		nivel_energizante.text = "No adquirida"

# Deshabilita compras cuyo precio supera el saldo actual y bloquea lo ya adquirido.
func _refrescar_estado_botones() -> void:
	var saldo: int = GameManager.dinero_total
	if not GameManager.mejoras_compradas.has("escaner_lvl2"):
		btn_mejorar_escaner.disabled = saldo < PRECIO_MEJORA_NIVEL_2
	if not GameManager.mejoras_compradas.has("cuter_lvl2"):
		btn_mejorar_cuter.disabled = saldo < PRECIO_MEJORA_NIVEL_2
	if not GameManager.mejoras_compradas.has("balanza_obtenida"):
		btn_comprar_balanza.disabled = saldo < PRECIO_COMPRA_BALANZA
	if not GameManager.mejoras_compradas.has("energizante_obtenido"):
		btn_comprar_energizante.disabled = saldo < PRECIO_COMPRA_ENERGIZANTE
	if GameManager.mejoras_compradas.has("balanza_obtenida"):
		btn_mejorar_balanza.disabled = saldo < PRECIO_MEJORA_NIVEL_2
	if GameManager.mejoras_compradas.has("energizante_obtenido"):
		btn_mejorar_energizante.disabled = saldo < PRECIO_MEJORA_NIVEL_2

func _comprar_mejora_escaner() -> void:
	if _pagar(PRECIO_MEJORA_NIVEL_2):
		GameManager.registrar_mejora("escaner_lvl2")
		EventBus.herramienta_mejorada.emit("escaner", 2)
		_refrescar_tienda()

func _comprar_mejora_cuter() -> void:
	if _pagar(PRECIO_MEJORA_NIVEL_2):
		GameManager.registrar_mejora("cuter_lvl2")
		EventBus.herramienta_mejorada.emit("cuter", 2)
		_refrescar_tienda()

func _comprar_balanza() -> void:
	if _pagar(PRECIO_COMPRA_BALANZA):
		GameManager.registrar_mejora("balanza_obtenida")
		EventBus.herramienta_desbloqueada.emit("balanza")
		_refrescar_tienda()

func _mejorar_balanza() -> void:
	if _pagar(PRECIO_MEJORA_NIVEL_2):
		GameManager.registrar_mejora("balanza_lvl2")
		EventBus.herramienta_mejorada.emit("balanza", 2)
		_refrescar_tienda()

func _comprar_energizante() -> void:
	if _pagar(PRECIO_COMPRA_ENERGIZANTE):
		GameManager.registrar_mejora("energizante_obtenido")
		EventBus.herramienta_desbloqueada.emit("energizante")
		_refrescar_tienda()

func _mejorar_energizante() -> void:
	if _pagar(PRECIO_MEJORA_NIVEL_2):
		GameManager.registrar_mejora("energizante_lvl2")
		EventBus.herramienta_mejorada.emit("energizante", 2)
		_refrescar_tienda()

# Centraliza el pago de la tienda y actualiza la interfaz si no se pudo comprar.
func _pagar(precio: int) -> bool:
	var pago_exitoso: bool = GameManager.gastar_dinero(precio)
	if not pago_exitoso:
		_refrescar_tienda()
	return pago_exitoso

func _on_button_cerrar_pressed() -> void:
	hide()
