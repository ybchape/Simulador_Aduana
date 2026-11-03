extends AcceptDialog

# Ref al nodo de audio AudioStreamPlayer3D 
@onready var audio_chicharra: AudioStreamPlayer3D = $SoundChicharra

func _ready() -> void:
	# Escucha la señal cuando se dispara el evento de alta demanda desde el gestor
	EventBus.evento_alta_demanda_iniciado.connect(_on_evento_iniciado)

	# Connect cuando presiona el botón "OK" del cartel
	confirmed.connect(_on_cartel_aceptado)

func _on_evento_iniciado(_duracion: float) -> void:
	dialog_text = "¡ALTA DEMANDA! El flujo de paquetes aumentó significativamente. ¡A trabajar!"
	title = "TURNO DE ALTA DEMANDA"
	
	# LIBERA EL MOUSE para que puedas hacer clic libremente
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	popup_centered() # Muestra el cartel en el centro de la pantalla

	# Reproduce la chicharra e al aparecer el cartel 
	if audio_chicharra and not audio_chicharra.playing:
		audio_chicharra.play()

func _on_cartel_aceptado() -> void:
	# Avisa al juego que el jugador ya leyó el cartel y dio OK para iniciar el evento
	EventBus.emit_signal("alta_demanda_confirmada")
