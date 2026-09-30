extends Control

# Simulamos que empiezas el día con $500 para poder probar
var dinero_actual = 500 



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
	
func _actualizar_pantalla():
	texto_dinero.text = "Dinero disponible: $" + str(dinero_actual)

# --- BOTONES DEL ESCÁNER  ---
func _on_btn_mejorar_pressed() -> void:
	var precio_mejora_escaner = 300
	
	if dinero_actual >= precio_mejora_escaner:
		dinero_actual -= precio_mejora_escaner
		_actualizar_pantalla()
		
		btn_mejorar_escaner.text = "¡Adquirido!"
		btn_mejorar_escaner.disabled = true
		
		# ¡Aquí actualizamos el texto dinámicamente!
		nivel_escaner.text = "Nivel 2"
	else:
		btn_mejorar_escaner.text = "Dinero insuficiente"
		await get_tree().create_timer(1.5).timeout
		btn_mejorar_escaner.text = "Mejorar: $300"
# --- 2. CÚTER ---
func _on_mejorar_cuter_pressed() -> void:
	var precio = 300
	
	if dinero_actual >= precio:
		dinero_actual -= precio
		_actualizar_pantalla()
		
		btn_mejorar_cuter.text = "¡Adquirido!"
		btn_mejorar_cuter.disabled = true
		
		# ¡Nuevo! Actualizamos el texto del Cúter
		nivel_cutar.text = "Nivel 2"
	else:
		btn_mejorar_cuter.text = "Dinero insuficiente"
		await get_tree().create_timer(1.5).timeout
		btn_mejorar_cuter.text = "Mejorar: $300"
# --- 3. BALANZA ---
func _on_comprar_balanza_pressed() -> void:
	var precio = 450
	
	if dinero_actual >= precio:
		dinero_actual -= precio
		_actualizar_pantalla()
		
		btn_comprar_balanza.text = "¡Adquirido!"
		btn_comprar_balanza.disabled = true
		btn_mejorar_balanza.visible = true # Aparece la mejora
		
		# ¡Nuevo! Actualizamos el texto de la Balanza
		nivel_balanza.text = "¡Sensor Inteligente activado!"
	else:
		btn_comprar_balanza.text = "Dinero insuficiente"
		await get_tree().create_timer(1.5).timeout
		btn_comprar_balanza.text = "Comprar: $450"

# --- 4. ENERGIZANTE ---
func _on_comprar_energizante_pressed() -> void:
	var precio = 150
	
	if dinero_actual >= precio:
		dinero_actual -= precio
		_actualizar_pantalla()
		
		btn_comprar_energizante.text = "¡Adquirido!"
		btn_comprar_energizante.disabled = true
		
		# Esta es la línea clave que lo vuelve a hacer visible:
		btn_mejorar_energizante.visible = true
	else:
		btn_comprar_energizante.text = "Dinero insuficiente"
		await get_tree().create_timer(1.5).timeout
		btn_comprar_energizante.text = "Comprar: $150"


func _on_button_cerrar_pressed() -> void:
	self.hide() # Esto oculta la ventana entera
