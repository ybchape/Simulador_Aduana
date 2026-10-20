extends CanvasLayer

@onready var barra_energia: TextureProgressBar = $Barra_Energia

# La energía siempre arranca en 100
var energia_actual: float = 100.0

func _ready() -> void:
	EventBus.decision_tomada.connect(_on_decision_tomada)
	# Escucha la confirmación del cartel para fijar la energía a la mitad
	EventBus.cansancio_confirmado.connect(_on_cansancio_confirmado)
	reiniciar_energia()

# Reinicia la barra al 100%
func reiniciar_energia() -> void:
	energia_actual = 100.0
	actualizar_interfaz()

func _on_cansancio_confirmado() -> void:
	# La energía baja a la mitad (50%) inmediatamente al arrancar la crisis
	energia_actual = 50.0
	actualizar_interfaz()

# Cada vez que se procesa un pedido (decisión tomada), resta un 2%
func _on_decision_tomada(_fue_permitido: bool) -> void:
	energia_actual -= 2.0
	actualizar_interfaz()

# Actualiza el nodo visual
func actualizar_interfaz() -> void:
	if barra_energia:
		# Clamp asegura que la barra nunca baje de 0 ni supere 100
		barra_energia.value = clamp(energia_actual, 0.0, 100.0)
