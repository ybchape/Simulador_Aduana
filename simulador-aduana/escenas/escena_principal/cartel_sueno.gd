extends ConfirmationDialog

func _ready() -> void:
	# Escucha cuando el juego decide tirar este evento
	EventBus.evento_sueno_iniciado.connect(_on_evento_iniciado)
	
	# Cuando el jugador toca "Ok", dispara el efecto
	confirmed.connect(_on_confirmado)
	
	# Ocultamos el botón "Cancelar" porque no podés elegir no tener sueño
	get_cancel_button().hide() 

func _on_evento_iniciado() -> void:
	title = "¡MALA NOCHE!"
	dialog_text = "No pudiste dormir bien. Tu energía inicial está al 30% y te cansarás el doble de rápido durante el turno.\n\nVas a necesitar comprar energizantes en la tienda." 
	
	ok_button_text = "Comenzar jornada"
	
	# Libera el mouse para que puedas clickear
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	popup_centered()

func _on_confirmado() -> void:
	# Le avisa al HUD de energía que aplique los recortes
	EventBus.sueno_confirmado.emit()
