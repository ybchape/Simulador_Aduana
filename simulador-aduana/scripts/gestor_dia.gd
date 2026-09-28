class_name GestorDia
extends Node

@export var meta_pedidos_dia: int = 3 # objetivo configurable desde el inspector

var pedidos_procesados: int = 0
var dia_terminado: bool = false

func _ready() -> void:
	# suscribe a la señal cuando el jugador presiona un botón
	EventBus.decision_tomada.connect(_on_decision_tomada)
	
	# Emite el progreso inicial en cuanto inicia la escena (0 / meta)
	# call_deferred para asegurar que la UI ya esté cargada en escena
	call_deferred("_notificar_progreso_inicial")

func _notificar_progreso_inicial() -> void:
	EventBus.progreso_dia_actualizado.emit(pedidos_procesados, meta_pedidos_dia)

func _on_decision_tomada(_fue_permitido: bool) -> void:
	if dia_terminado:
		return

	# Incrementa el contador
	pedidos_procesados += 1
	
	# Notifica el cambio de avance
	EventBus.progreso_dia_actualizado.emit(pedidos_procesados, meta_pedidos_dia)
	
	print("Progreso del día: ", pedidos_procesados, " / ", meta_pedidos_dia)

	# Verifica si completó los pedidos diarios
	if pedidos_procesados >= meta_pedidos_dia:
		dia_terminado = true
		EventBus.objetivo_dia_alcanzado.emit()
		print("¡Objetivo del día alcanzado!")
