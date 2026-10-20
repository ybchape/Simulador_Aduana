extends Node

@export var tiempo_min_duracion: float = 30.0
@export var tiempo_max_duracion: float = 40.0

var esta_cansado: bool = false

func _ready() -> void:
	# Programa el evento aleatorio aproximadamente a mitad del día (prueba a los 15-20 segundos de iniciar)
	var tiempo_espera_evento = randf_range(12.0, 25.0)
	get_tree().create_timer(tiempo_espera_evento).timeout.connect(disparar_evento_cansancio)

func disparar_evento_cansancio() -> void:
	esta_cansado = true
	var duracion_evento = randf_range(tiempo_min_duracion, tiempo_max_duracion)
	
	print("¡EVENTO DE CANSANCIO INICIADO! Duración: ", duracion_evento, " segundos.")
	EventBus.evento_cansancio_iniciado.emit(duracion_evento)
	
	# Timer para finalizar el evento automáticamente
	await get_tree().create_timer(duracion_evento).timeout
	
	esta_cansado = false
	print("El evento de cansancio ha finalizado.")
	EventBus.evento_cansancio_finalizado.emit()
