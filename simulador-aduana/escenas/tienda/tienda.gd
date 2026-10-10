extends Control

# CORI CODE- saque la plata fija de $500 para usar el GM

# Cambia "Label" por el nombre exacto que le pusiste a tu texto de dinero arriba
@onready var texto_dinero = $Label
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

func _ready():
	_actualizar_pantalla()
	_restaurar_estado_compras() # CORI CODE- load las mejoras ya compradas al iniciar
	
func _actualizar_pantalla():
	# CAMBIO- Ahora lee directo del GM
	if GameManager:
		texto_dinero.text = "Dinero disponible: $" + str(GameManager.dinero_total)

# CORI CODE- restaura el estado de los botones si la mejora ya fue comprada 
func _restaurar_estado_compras() -> void:
	if not GameManager:
		return

	if "escaner_lvl2" in GameManager.mejoras_compradas:
		btn_mejorar_escaner.text = "¡Adquirido!"
		btn_mejorar_escaner.disabled = true
		nivel_escaner.text = "Nivel 2"

	if "cuter_lvl2" in GameManager.mejoras_compradas:
		btn_mejorar_cuter.text = "¡Adquirido!"
		btn_mejorar_cuter.disabled = true
		nivel_cutar.text = "Nivel 2"

	if "balanza_obtenida" in GameManager.mejoras_compradas:
		btn_comprar_balanza.text = "¡Adquirido!"
		btn_comprar_balanza.disabled = true
		btn_mejorar_balanza.visible = true
		nivel_balanza.text = "balanza obtenida"

	if "energizante_obtenido" in GameManager.mejoras_compradas:
		btn_comprar_energizante.text = "¡Adquirido!"
		btn_comprar_energizante.disabled = true
		btn_mejorar_energizante.visible = true

# botones del escaner
func _on_btn_mejorar_pressed() -> void:
	var precio_mejora_escaner = 300
	
	# CORI CODE- Compara y resta el dinero en el GM
	if GameManager and GameManager.dinero_total >= precio_mejora_escaner:
		GameManager.dinero_total -= precio_mejora_escaner
		GameManager.mejoras_compradas.append("escaner_lvl2") 
		_actualizar_pantalla()

		btn_mejorar_escaner.text = "¡Adquirido!"
		btn_mejorar_escaner.disabled = true

		# ¡Aquí actualizamos el texto dinámicamente!
		nivel_escaner.text = "Nivel 2"
	else:
		btn_mejorar_escaner.text = "Dinero insuficiente"
		await get_tree().create_timer(1.5).timeout
		btn_mejorar_escaner.text = "Mejorar: $300"

# cutter
func _on_mejorar_cuter_pressed() -> void:
	var precio = 300
	
	# CORI CODE- Compara y resta el dinero en el GM (lo mismo con todos los objetos)
	if GameManager and GameManager.dinero_total >= precio:
		GameManager.dinero_total -= precio
		GameManager.mejoras_compradas.append("cuter_lvl2") 
		_actualizar_pantalla()
		
		btn_mejorar_cuter.text = "¡Adquirido!"
		btn_mejorar_cuter.disabled = true

		nivel_cutar.text = "Nivel 2"
	else:
		btn_mejorar_cuter.text = "Dinero insuficiente"
		await get_tree().create_timer(1.5).timeout
		btn_mejorar_cuter.text = "Mejorar: $300"

# balanza
func _on_comprar_balanza_pressed() -> void:
	var precio = 450

	if GameManager and GameManager.dinero_total >= precio:
		GameManager.dinero_total -= precio
		GameManager.mejoras_compradas.append("balanza_obtenida") 
		_actualizar_pantalla()

		btn_comprar_balanza.text = "¡Adquirido!"
		btn_comprar_balanza.disabled = true
		btn_mejorar_balanza.visible = true # Aparece la mejora

		nivel_balanza.text = "balanza obtenida"
	else:
		btn_comprar_balanza.text = "Dinero insuficiente"
		await get_tree().create_timer(1.5).timeout
		btn_comprar_balanza.text = "Comprar: $450"

# energizante
func _on_comprar_energizante_pressed() -> void:
	var precio = 150

	if GameManager and GameManager.dinero_total >= precio:
		GameManager.dinero_total -= precio
		GameManager.mejoras_compradas.append("energizante_obtenido") 
		_actualizar_pantalla()

		btn_comprar_energizante.text = "¡Adquirido!"
		btn_comprar_energizante.disabled = true

		# lo vuelve a hacer visible al energizante
		btn_mejorar_energizante.visible = true
	else:
		btn_comprar_energizante.text = "Dinero insuficiente"
		await get_tree().create_timer(1.5).timeout
		btn_comprar_energizante.text = "Comprar: $150"

func _on_button_cerrar_pressed() -> void:
	self.hide() # Esto oculta la ventana entera
