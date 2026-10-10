extends Node

var dia_actual: int = 1
var dinero_total: int = 0
var pedidos_realizados_hoy: int = 0
var mejoras_compradas: Array = []

# cant pedidos por dia laboral
const OBJETIVOS_POR_DIA = {
	1: 3,
	2: 6,
	3: 10,
	4: 15
}

func obtener_objetivo_actual() -> int:
	return OBJETIVOS_POR_DIA.get(dia_actual, 15) # Por defecto 15 si pasa del día 4

func avanzar_siguiente_dia() -> void:
	dia_actual += 1
	pedidos_realizados_hoy = 0
	# la plata y mejoras se conservan automáticamente 

func acumular_dinero(cantidad: float) -> void:
	dinero_total += int(cantidad)
	print("Dinero total acumulado: $", dinero_total)
