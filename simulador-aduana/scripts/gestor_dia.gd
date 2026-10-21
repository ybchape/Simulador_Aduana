class_name GestorDia
extends Node

@export var meta_pedidos_dia: int = 3 # objetivo configurable desde el inspector

var pedidos_procesados: int = 0
var dia_terminado: bool = false

func _ready() -> void:
	
	EventBus.decision_tomada.connect(_on_decision_tomada)
	
	# Notifica el progreso inicial
	call_deferred("_notificar_progreso_inicial")

func _notificar_progreso_inicial() -> void:
	_actualizar_meta()
	# Al arrancar la escena, asegura que el contador empiece sincronizado
	pedidos_procesados = 0
	EventBus.progreso_dia_actualizado.emit(pedidos_procesados, meta_pedidos_dia)

func _actualizar_meta() -> void:
	if GameManager:
		meta_pedidos_dia = GameManager.obtener_objetivo_actual()


func _on_decision_tomada(_fue_permitido: bool) -> void:
	if dia_terminado:
		return

# Asegura tener la meta actualizada del día actual
	_actualizar_meta()
	
# Sumamos +1 en el contador local en cuanto se presiona el botón
	pedidos_procesados += 1
	
	# Notifica el cambio de avance
	EventBus.progreso_dia_actualizado.emit(pedidos_procesados, meta_pedidos_dia)
	
	print("Progreso del día: ", pedidos_procesados, " / ", meta_pedidos_dia)

	# Verifica si completó los pedidos diarios
	if pedidos_procesados >= meta_pedidos_dia:
		dia_terminado = true
		# Espera al final del frame actual para dar tiempo a GameManager de procesar la plata
		call_deferred("_finalizar_jornada")
		
func _finalizar_jornada() -> void:
	#  empaqueta las estadísticas cuando GameManager ya sumó el último pedido
	var stats_turno = GameManager.obtener_stats_resumen()
	EventBus.objetivo_dia_alcanzado.emit(stats_turno)
