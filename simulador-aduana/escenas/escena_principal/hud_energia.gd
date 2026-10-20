extends CanvasLayer

@onready var barra_energia: TextureProgressBar = $Barra_Energia

# La energía siempre arranca en 100
var energia_actual: float = 100.0

func _ready() -> void:
	# Se conecta a la señal del EventBus que salta cuando aprobás/rechazás un pedido
	EventBus.decision_tomada.connect(_on_decision_tomada)
	
	# Reinicia la energía al 100% al cargar la escena (inicio de jornada)
	reiniciar_energia()

# Reinicia la barra al 100%
func reiniciar_energia() -> void:
	energia_actual = 100.0
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
