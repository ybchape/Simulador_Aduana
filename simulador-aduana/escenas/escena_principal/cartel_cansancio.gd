extends AcceptDialog

func _ready() -> void:
	# Escucha la señal cuando salta la posibilidad del evento
	EventBus.evento_cansancio_iniciado.connect(_on_evento_iniciado)
	confirmed.connect(_on_cartel_aceptado)

func _on_evento_iniciado(_duracion: float) -> void:
	dialog_text = "Las jornadas son muy largas y los días empiezan a pesar. Tu personaje está demasiado cansado y sus reflejos se han vuelto lentos."
	title = "¡AGOTAMIENTO LABORAL!"
	popup_centered() # Muestra el cartel en el centro de la pantalla

func _on_cartel_aceptado() -> void:
	# Avisa al juego que el jugador ya leyó el cartel para iniciar la lentitud y bajar la energía a la mitad
	EventBus.cansancio_confirmado.emit()
