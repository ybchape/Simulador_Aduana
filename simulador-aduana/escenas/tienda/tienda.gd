extends Control

# Simulamos que empiezas el día con $500 para poder probar
var dinero_actual = 500 

# Cambia "Label" por el nombre exacto que le pusiste a tu texto de dinero arriba
@onready var texto_dinero = $Label

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
		print("¡Escáner mejorado! Adquirido.")
		
		# Aquí luego pondremos el código para cambiar el texto a "Nivel 2: 6 usos"
	else:
		print("Dinero insuficiente")

# --- 2. CÚTER ---
func _on_mejorar_cuter_pressed() -> void:
	var precio = 300
	if dinero_actual >= precio:
		dinero_actual -= precio
		_actualizar_pantalla()
		print("¡Cúter mejorado! Adquirido.")
	else:
		print("Dinero insuficiente para el Cúter")

# --- 3. BALANZA ---
func _on_comprar_balanza_pressed() -> void:
	var precio = 450
	if dinero_actual >= precio:
		dinero_actual -= precio
		_actualizar_pantalla()
		print("¡Balanza comprada! Adquirido.")
	else:
		print("Dinero insuficiente para la Balanza")

# --- 4. ENERGIZANTE ---
func _on_comprar_energizante_pressed() -> void:
	var precio = 150
	if dinero_actual >= precio:
		dinero_actual -= precio
		_actualizar_pantalla()
		print("¡Energizante comprado! Adquirido.")
	else:
		print("Dinero insuficiente para el Energizante")
