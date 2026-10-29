extends AcceptDialog

func _ready() -> void:
	# Escucha la señal cuando se dispara el evento de alta demanda 
	EventBus.evento_alta_demanda_iniciado.connect(_on_evento_iniciado)
	#confirmed.connect(_on_cartel_aceptado)

func _on_evento_iniciado(_duracion: float) -> void:
	dialog_text = "¡ALTA DEMANDA! El flujo de paquetes aumentó significativamente. ¡A trabajar bajo presión!"
	title = "TURNO DE ALTA DEMANDA"
	popup_centered() # Muestra el cartel en el centro de la pantalla

#func _on_cartel_aceptado() -> void:
	# Avisa al juego que el jugador ya leyó el cartel para iniciar la lentitud y bajar la energía a la mitad
	#EventBus.cansancio_confirmado.emit()
