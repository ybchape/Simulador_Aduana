class_name GestorDia
extends Node

@export var meta_pedidos_dia: int = 3 # objetivo configurable desde el inspector

var pedidos_procesados: int = 0
var dia_terminado: bool = false

func _ready() -> void:
	# Obtiene del GameManager cuántos pedidos hacen falta para completar este día.
	if GameManager:
		meta_pedidos_dia = GameManager.obtener_objetivo_actual()

	# Cuenta las decisiones de aprobación/rechazo que llegan desde los botones.
	EventBus.decision_tomada.connect(_on_decision_tomada)

	# Emite el progreso inicial en cuanto inicia la escena (0 / meta)
	call_deferred("_notificar_progreso_inicial")

# Inicializa el HUD con el progreso del día después de que los nodos se conecten.
func _notificar_progreso_inicial() -> void:
	EventBus.progreso_dia_actualizado.emit(pedidos_procesados, meta_pedidos_dia)

# Cuenta cada decisión y emite el resumen cuando se alcanza la meta diaria.
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
		
		# Empaqueta las estadísticas acumuladas en GameManager
		var stats_turno = GameManager.obtener_stats_resumen()
		EventBus.objetivo_dia_alcanzado.emit(stats_turno)
