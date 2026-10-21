extends Node

@export var tiempo_min_duracion: float = 30.0
@export var tiempo_max_duracion: float = 40.0

var esta_cansado: bool = false

func _ready() -> void:
#  Si estamos en el Día 1, NUNCA se activa el evento de cansancio
	if GameManager and GameManager.dia_actual <= 1:
		print("Día 1: Evento de cansancio desactivado.")
		return
	
	#  Probabilidad del 60% de que ocurra en los días 2 en adelante
	if randf() < 0.6:
		# Se dispara aleatoriamente entre el segundo 15 y el 45 del día
		var tiempo_aleatorio = randf_range(15.0, 45.0)
		get_tree().create_timer(tiempo_aleatorio).timeout.connect(disparar_evento_cansancio)

func disparar_evento_cansancio() -> void:
	var duracion_evento = randf_range(tiempo_min_duracion, tiempo_max_duracion)
	print("¡EVENTO DE CANSANCIO PROGRAMADO! Mostrando cartel...")
	
	# MUESTRA el cartel
	EventBus.evento_cansancio_iniciado.emit(duracion_evento)
	
	# Espera a que el jugador cierre el cartel
	await EventBus.cansancio_confirmado
	
	# Activar la lentitud y el parpadeo
	esta_cansado = true
	
	# Timer para finalizar la crisis
	await get_tree().create_timer(duracion_evento).timeout
	
	esta_cansado = false
	print("El evento de cansancio ha finalizado.")
	EventBus.evento_cansancio_finalizado.emit()
