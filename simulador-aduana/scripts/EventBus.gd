extends Node
# Señal con la malla 3D del objeto que debe mostrarse en la pantalla del escáner.
signal escanear_objeto(forma_del_objeto)

signal pedido_en_zona(hay_pedido)
signal decision_tomada(fue_permitido)

# Señales de llegada de pedidos, decisiones del jugador y progreso diario.
signal progreso_dia_actualizado(pedidos_completados, meta_diaria)
signal objetivo_dia_alcanzado(stats_turno)
signal siguiente_pedido_solicitado
signal inspeccion_visualizada(datos: PedidoInfo)
signal inspeccion_completada(datos: PedidoInfo)

# Señales para actualizar el saldo y desbloquear o mejorar herramientas.
signal dinero_cambiado(nuevo_saldo: float)
signal herramienta_desbloqueada(id: String)
signal herramienta_mejorada(id: String, nivel: int)

# Señales del evento de cansancio y su confirmación.
signal evento_cansancio_iniciado(duracion: float)
signal evento_cansancio_finalizado
signal cansancio_confirmado # Salta cuando se cierra el cartel

## El saldo se gestiona en GameManager.dinero_total para que la tienda y el
## cierre de turno compartan una sola billetera. Esta función mantiene la API
## usada por GestorDia para pagar el neto del turno.
## Suma o resta dinero en GameManager y notifica a los suscriptores del EventBus.
func agregar_dinero(monto: float) -> void:
	if monto == 0.0 or not GameManager:
		return
	GameManager.acumular_dinero(monto)
	dinero_cambiado.emit(GameManager.dinero_total)

## Compatibilidad: las compras usan GameManager como fuente única del saldo.
## Devuelve false si no alcanza el dinero; en caso de éxito emite el saldo actualizado.
func gastar_dinero(monto: float) -> bool:
	if not GameManager:
		return false
	var pudo_pagar: bool = GameManager.gastar_dinero(int(monto))
	if pudo_pagar:
		dinero_cambiado.emit(GameManager.dinero_total)
	return pudo_pagar

# Autoload de señales: no necesita inicialización adicional por ahora.
func _ready() -> void:
	pass

# Se mantiene vacío; EventBus no ejecuta lógica por fotograma.
func _process(_delta: float) -> void:
	pass
	
	
	
