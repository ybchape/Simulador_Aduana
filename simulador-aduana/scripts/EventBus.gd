extends Node
#señal para detectar algo
signal escanear_objeto(forma_del_objeto)

signal pedido_en_zona(hay_pedido)
signal decision_tomada(fue_permitido)

#señales objetivo del dia
signal progreso_dia_actualizado(pedidos_completados, meta_diaria)
signal objetivo_dia_alcanzado(stats_turno)

#señales de tienda / inventario
signal dinero_cambiado(nuevo_saldo: float)
signal herramienta_desbloqueada(id: String)
signal herramienta_mejorada(id: String, nivel: int)

## Billetera compartida del jugador. Es la única fuente de verdad del saldo
## que gasta la tienda.
var billetera: float = 500.0

## Descuenta un monto exacto de la billetera. Devuelve true si se pudo pagar.
func gastar_dinero(monto: float) -> bool:
	if monto <= 0.0 or billetera < monto:
		return false
	billetera -= monto
	dinero_cambiado.emit(billetera)
	return true

## Suma un monto a la billetera (por ejemplo, la ganancia de un pedido).
func agregar_dinero(monto: float) -> void:
	if monto == 0.0:
		return
	billetera += monto
	dinero_cambiado.emit(billetera)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
	
