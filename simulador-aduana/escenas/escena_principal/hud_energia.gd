extends CanvasLayer

@onready var barra_energia: TextureProgressBar = $Barra_Energia

# --- Configuración del desgaste pasivo ---
@export var velocidad_desgaste_base: float = 0.8 # Porcentaje de energía que baja por segundo
var multiplicador_desgaste: float = 1.0

# La energía siempre arranca en 100
var energia_actual: float = 100.0
var esta_en_crisis_cansancio: bool = false # Controla la restricción del evento
var turno_activo: bool = true


func _ready() -> void:
# Escucha los consumibles y eventos del juego
	EventBus.consumible_usado.connect(_on_consumible_usado)
	EventBus.cansancio_confirmado.connect(_on_cansancio_iniciado)
	EventBus.evento_cansancio_finalizado.connect(_on_cansancio_finalizado)
	EventBus.alta_demanda_confirmada.connect(_on_alta_demanda_iniciada)
	EventBus.evento_alta_demanda_finalizado.connect(_on_alta_demanda_finalizada)
	reiniciar_energia()

func _process(delta: float) -> void:
	if not turno_activo:
		return
		
	# Desgaste continuo y natural por segundo
	if energia_actual > 0.0:
		var desgaste = velocidad_desgaste_base * multiplicador_desgaste * delta
		energia_actual = maxf(0.0, energia_actual - desgaste)
		actualizar_interfaz()


# Reinicia la barra al 100%
func reiniciar_energia() -> void:
	energia_actual = 100.0
	multiplicador_desgaste = 1.0
	esta_en_crisis_cansancio = false
	turno_activo = true
	actualizar_interfaz()

# --- Handlers de Eventos ---
func _on_cansancio_iniciado() -> void:
	esta_en_crisis_cansancio = true
	# Durante la crisis de cansancio la energía se consume el doble de rápido
	multiplicador_desgaste = 2.0


func _on_cansancio_finalizado() -> void:
	esta_en_crisis_cansancio = false
	multiplicador_desgaste = 1.0

func _on_alta_demanda_iniciada() -> void:
	# La tensión aumenta el consumo a 1.5x
	multiplicador_desgaste = 1.5

func _on_alta_demanda_finalizada() -> void:
	multiplicador_desgaste = 1.0

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

# Mantener por compatibilidad si la señal sigue emitiéndose, pero vacía
func _on_decision_tomada(_fue_permitido: bool) -> void:
	pass

# Actualiza el nodo visual
func actualizar_interfaz() -> void:
	if barra_energia:
		# Clamp asegura que la barra nunca baje de 0 ni supere 100
		barra_energia.value = clamp(energia_actual, 0.0, 100.0)
