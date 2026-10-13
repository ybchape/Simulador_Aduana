extends Node
#señal para detectar algo
signal escanear_objeto(forma_del_objeto)

signal pedido_en_zona(hay_pedido)
signal decision_tomada(fue_permitido)

#señales objetivo del dia
signal progreso_dia_actualizado(pedidos_completados, meta_diaria)
signal objetivo_dia_alcanzado(stats_turno)

signal energia_cambiada(nueva_energia: float)
signal evento_cansancio_iniciado(duracion: float)
signal evento_cansancio_finalizado()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
	
