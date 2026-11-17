extends ConfirmationDialog

@onready var audio_stream_player: AudioStreamPlayer3D = $SoundCorteLuz
var _costo_reparacion_actual: int = 0

func _ready() -> void:
	# Escucha cuando salta la posibilidad del evento
	EventBus.evento_corte_luz_iniciado.connect(_on_evento_iniciado)
	
	# Conecta las señales de los botones del cartel
	confirmed.connect(_on_pagar_reparacion)
	canceled.connect(_on_esperar)

func _on_evento_iniciado(duracion: float, costo: float) -> void:
	_costo_reparacion_actual = int(costo)
	title = "¡APAGÓN EN LA ADUANA!"
	dialog_text = "Se cortó la luz en el puesto de trabajo. El escáner quedó inhabilitado por falta de energía.\n\n¿Querés pagar para reparar la luz de inmediato o preferís esperar?" 
	get_ok_button().visible = true
	get_ok_button().disabled = false
	
	ok_button_text = "Pagar Reparación ($" + str(int(costo)) + ")"
	cancel_button_text = "Esperar"

#play sonido de corte de luz
	if audio_stream_player and audio_stream_player.stream:
		audio_stream_player.play()
	
	# Espera 1 segundo mientras la luz se apaga en la escena 3D
	await get_tree().create_timer(1.0).timeout
	
	# LIBERA EL MOUSE para que puedas hacer clic libremente
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	popup_centered() # Muestra el cartel centrado

func _on_pagar_reparacion() -> void:
	# Verifica si le alcanza el dinero en GameManager antes de intentar pagar
	if GameManager.dinero_total < _costo_reparacion_actual:
		dialog_text = "DINERO INSUFICIENTE (Necesitás $" + str(_costo_reparacion_actual) + " y tenés $" + str(GameManager.dinero_total) + ").\n\nNo podés costear la reparación, vas a tener que esperar a que vuelva la luz."
		
		# Oculta el botón de pagar para que solo le quede la opción de "Esperar"
		get_ok_button().visible = false
		
		# Como ConfirmationDialog se cierra automáticamente al presionar OK, lo volvemos a abrir
		popup_centered()
		return
	#  Avisa que el cartel fue leído/cerrado para iniciar el estado de corte
	EventBus.corte_luz_confirmado.emit()
	#  Emite la señal para intentar pagar la reparación
	EventBus.pagar_reparacion_corte_luz.emit()

func _on_esperar() -> void:
	# El jugador elige no pagar, solo confirma el inicio del apagón
	EventBus.corte_luz_confirmado.emit()
