extends Node

signal dinero_cambiado(nuevo_saldo: int)

var dia_actual: int = 1
# La billetera persistente empieza vacía y es la fuente única de saldo.
var dinero_total: int = 0
var pedidos_realizados_hoy: int = 0
var mejoras_compradas: Array[String] = []

# Cantidad de pedidos por día laboral.
const OBJETIVOS_POR_DIA: Dictionary = {
	1: 3,
	2: 6,
	3: 10,
	4: 15,
}

func obtener_objetivo_actual() -> int:
	return OBJETIVOS_POR_DIA.get(dia_actual, 15)

func avanzar_siguiente_dia() -> void:
	dia_actual += 1
	pedidos_realizados_hoy = 0
	# El saldo y las compras se conservan entre días.

func gastar_dinero(cantidad: int) -> bool:
	if cantidad <= 0 or dinero_total < cantidad:
		return false
	dinero_total -= cantidad
	dinero_cambiado.emit(dinero_total)
	return true

func acumular_dinero(cantidad: float) -> void:
	# Acepta ganancias positivas y balances netos negativos.
	dinero_total += int(cantidad)
	dinero_cambiado.emit(dinero_total)
	print("Dinero total acumulado: $", dinero_total)

func registrar_mejora(id: String) -> void:
	if not mejoras_compradas.has(id):
		mejoras_compradas.append(id)
