extends CanvasLayer

@onready var barra_energia: TextureProgressBar = $Barra_Energia

# La energía siempre arranca en 100
var energia_actual: float = 100.0
var esta_en_crisis_cansancio: bool = false # Controla la restricción del evento


func _ready() -> void:
	EventBus.decision_tomada.connect(_on_decision_tomada)
	# Escucha la confirmación del cartel para fijar la energía a la mitad
	EventBus.cansancio_confirmado.connect(_on_cansancio_confirmado)
	EventBus.evento_cansancio_finalizado.connect(_on_cansancio_finalizado)
	# Escucha cuando el jugador usa un consumible desde la hotbar/inventario
	EventBus.consumible_usado.connect(_on_consumible_usado)
	reiniciar_energia()

# Reinicia la barra al 100%
func reiniciar_energia() -> void:
	energia_actual = 100.0
	actualizar_interfaz()

func _on_cansancio_confirmado() -> void:
	esta_en_crisis_cansancio = true
	# La energía baja a la mitad (50%) inmediatamente al arrancar la crisis
	energia_actual = 50.0
	actualizar_interfaz()

func _on_cansancio_finalizado() -> void:
	esta_en_crisis_cansancio = false

# Cada vez que se procesa un pedido (decisión tomada), resta un 2%
func _on_decision_tomada(_fue_permitido: bool) -> void:
	energia_actual -= 2.0
	actualizar_interfaz()

#  Procesa el uso del Energizante / Café ---
func _on_consumible_usado(id: String, nivel: int) -> void:
	#  Durante el evento de cansancio no tiene ningún efecto
	if esta_en_crisis_cansancio:
		# Avisa visualmente al inventario para mostrar el cartel de bloqueo
		var inv = get_tree().get_first_node_in_group("inventario")
		if inv and inv.has_method("mostrar_aviso"):
			inv.mostrar_aviso("¡Sin efecto durante el agotamiento!")
		print("Consumible bloqueado: El personaje está bajo evento de cansancio.")
		return

	#  Nivel 1 (+10), Nivel 2 (+20), Nivel 3 (+30)
	var incremento: float = 10.0 * float(nivel)
	
	energia_actual = clamp(energia_actual + incremento, 0.0, 100.0)
	actualizar_interfaz()
	
	# Confirma la acción en pantalla
	var inv = get_tree().get_first_node_in_group("inventario")
	if inv and inv.has_method("mostrar_aviso"):
		inv.mostrar_aviso("+" + str(int(incremento)) + "% Energía")


# Actualiza el nodo visual
func actualizar_interfaz() -> void:
	if barra_energia:
		# Clamp asegura que la barra nunca baje de 0 ni supere 100
		barra_energia.value = clamp(energia_actual, 0.0, 100.0)
