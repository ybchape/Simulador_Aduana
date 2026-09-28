class_name GestorDia
extends Node

@export var meta_pedidos_dia: int = 3 # objetivo configurable desde el inspector
@export var valor_pedido_base: float = 50.0 #valores de los pedidos
@export var penalizacion_error: float = 50.0
@export var penalizacion_cutter: float = 20.0

var pedidos_procesados: int = 0
var pedidos_correctos: int = 0
var dinero_obtenido: float = 0.0
var dinero_descontado: float = 0.0
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
	
	# Lógica temporal de prueba: suma la ganancia base del pedido
	var fue_correcto = true 

	if fue_correcto:
		pedidos_correctos += 1
		dinero_obtenido += valor_pedido_base
	else:
		dinero_descontado += penalizacion_error
	
	
	
	# Notifica el cambio de avance
	EventBus.progreso_dia_actualizado.emit(pedidos_procesados, meta_pedidos_dia)
	
	print("Progreso del día: ", pedidos_procesados, " / ", meta_pedidos_dia)

	# Verifica si completó los pedidos diarios
	if pedidos_procesados >= meta_pedidos_dia:
		dia_terminado = true
	# Empaqueta las estadísticas de la jornada
		var stats_turno = {
			"correctos": pedidos_correctos,
			"total": meta_pedidos_dia,
			"ganado": dinero_obtenido,
			"descontado": dinero_descontado,
			"neto": dinero_obtenido - dinero_descontado
		}
		
		EventBus.objetivo_dia_alcanzado.emit(stats_turno)
