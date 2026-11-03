extends ConfirmationDialog


func _ready() -> void:
	# Escucha cuando salta la posibilidad del evento
	EventBus.evento_corte_luz_iniciado.connect(_on_evento_iniciado)
	
	# Conecta las señales de los botones del cartel
	confirmed.connect(_on_pagar_reparacion)
	canceled.connect(_on_esperar)

func _on_evento_iniciado(duracion: float, costo: float) -> void:
	title = "¡APAGÓN EN LA ADUANA!"
	dialog_text = "Se cortó la luz en el puesto de trabajo. El escáner quedó inhabilitado por falta de energía.\n\n¿Querés pagar $%d para reparar la luz de inmediato o preferís esperar %.0f segundos?" % [costo, duracion]
	
	ok_button_text = "Pagar Reparación ($" + str(int(costo)) + ")"
	cancel_button_text = "Entendido / Esperar"
	
	popup_centered() # Muestra el cartel centrado

func _on_pagar_reparacion() -> void:
	#  Avisa que el cartel fue leído/cerrado para iniciar el estado de corte
	EventBus.corte_luz_confirmado.emit()
	#  Emite la señal para intentar pagar la reparación
	EventBus.pagar_reparacion_corte_luz.emit()

func _on_esperar() -> void:
	# El jugador elige no pagar, solo confirma el inicio del apagón
	EventBus.corte_luz_confirmado.emit()
