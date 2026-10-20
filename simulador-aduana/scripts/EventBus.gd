extends Node
#señal para detectar algo
signal escanear_objeto(forma_del_objeto)

signal pedido_en_zona(hay_pedido)
signal decision_tomada(fue_permitido)

#señales objetivo del dia
signal progreso_dia_actualizado(pedidos_completados, meta_diaria)
signal objetivo_dia_alcanzado(stats_turno)
signal siguiente_pedido_solicitado

#señales de tienda / inventario
signal dinero_cambiado(nuevo_saldo: float)
signal herramienta_desbloqueada(id: String)
signal herramienta_mejorada(id: String, nivel: int)

#Evento Cansancio
signal evento_cansancio_iniciado(duracion: float)
signal evento_cansancio_finalizado

## El saldo se gestiona en GameManager.dinero_total para que la tienda y el
## cierre de turno compartan una sola billetera. Esta función mantiene la API
## usada por GestorDia para pagar el neto del turno.
func agregar_dinero(monto: float) -> void:
	if monto == 0.0 or not GameManager:
		return
	GameManager.acumular_dinero(monto)
	dinero_cambiado.emit(GameManager.dinero_total)

## Compatibilidad: las compras usan GameManager como fuente única del saldo.
func gastar_dinero(monto: float) -> bool:
	if not GameManager:
		return false
	var pudo_pagar: bool = GameManager.gastar_dinero(int(monto))
	if pudo_pagar:
		dinero_cambiado.emit(GameManager.dinero_total)
	return pudo_pagar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
	
