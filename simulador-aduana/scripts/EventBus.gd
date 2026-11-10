extends Node
#señal para detectar algo
signal escanear_objeto(forma_del_objeto)
signal inspeccion_visualizada(datos)
signal inspeccion_completada(datos)

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
signal tienda_abierta
signal tienda_cerrada

# Se emite cuando el jugador elige (o suelta) una herramienta activa. "" = ninguna.
signal herramienta_seleccionada(id: String)

#Evento Cansancio
signal evento_cansancio_iniciado(duracion: float)
signal evento_cansancio_finalizado
signal cansancio_confirmado # Salta cuando se cierra el cartel
signal evento_alta_demanda_iniciado(duracion: float)
signal evento_alta_demanda_finalizado
signal alta_demanda_confirmada

#  Evento Corte de Luz 
signal evento_corte_luz_iniciado(duracion: float, costo_reparacion: float)
signal evento_corte_luz_finalizado
signal corte_luz_confirmado
signal pagar_reparacion_corte_luz

# Emite la orden de restaurar energía: id ("energizante" o "cafe") y el nivel actual del consumible
signal consumible_usado(id: String, nivel: int)

# Evento Sueño / Insomnio 
signal evento_sueno_iniciado
signal evento_sueno_finalizado
signal sueno_confirmado


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
	
	
	
