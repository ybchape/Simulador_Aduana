extends CanvasLayer

@onready var barra_energia: TextureProgressBar = $Barra_Energia

# --- Configuración del desgaste pasivo ---
@export var velocidad_desgaste_base: float = 0.7 # Porcentaje de energía que baja por segundo
var multiplicador_desgaste: float = 1.0

# La energía siempre arranca en 100
var energia_actual: float = 100.0
var esta_en_crisis_cansancio: bool = false # Controla la restricción del evento
var sueno_activo: bool = false # Controla si el evento de insomnio está activo
var turno_activo: bool = true


func _ready() -> void:
	# Escucha los consumibles y eventos del juego
	EventBus.consumible_usado.connect(_on_consumible_usado)
	EventBus.cansancio_confirmado.connect(_on_cansancio_iniciado)
	EventBus.evento_cansancio_finalizado.connect(_on_cansancio_finalizado)
	EventBus.alta_demanda_confirmada.connect(_on_alta_demanda_iniciada)
	EventBus.evento_alta_demanda_finalizado.connect(_on_alta_demanda_finalizada)
	
	# Evento de Sueño
	EventBus.sueno_confirmado.connect(_on_sueno_iniciado)
	EventBus.evento_sueno_finalizado.connect(_on_sueno_finalizado)
	
	reiniciar_energia()


func _process(delta: float) -> void:
	if not turno_activo:
		return
		
	# Desgaste constante de energía (afectado por el multiplicador)
	energia_actual -= (velocidad_desgaste_base * multiplicador_desgaste) * delta
	actualizar_interfaz()
	
	# CRITERIO 4: Game Over si la energía llega a 0
	if energia_actual <= 0.0:
		energia_actual = 0.0
		turno_activo = false
		GameManager.trigger_game_over_por_energia()


# Reinicia la barra al 100%
func reiniciar_energia() -> void:
	energia_actual = 100.0
	multiplicador_desgaste = 1.0
	sueno_activo = false
	esta_en_crisis_cansancio = false
	turno_activo = true
	actualizar_interfaz()


# --- Evento de Sueño ---
# CRITERIO 1, 2 y 5: Inicia con 50%, actualiza barra y se agota más rápido
func _on_sueno_iniciado() -> void:
	sueno_activo = true
	energia_actual = 30.0 
	multiplicador_desgaste = 1.4 # Se agota el doble de rápido
	actualizar_interfaz() # Se refleja de inmediato en la UI

func _on_sueno_finalizado() -> void:
	sueno_activo = false
	multiplicador_desgaste = 1.0


# --- Handlers de Eventos Existentes ---
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


# --- Lógica de Consumibles Unificada (Solo Energizante) ---
func _on_consumible_usado(id: String, nivel: int) -> void:
	# 1. Bloqueo si el personaje está en el otro evento de cansancio extremo
	if esta_en_crisis_cansancio:
		var inv = get_tree().get_first_node_in_group("inventario")
		if inv and inv.has_method("mostrar_aviso"):
			inv.mostrar_aviso("¡Sin efecto durante el agotamiento!")
		print("Consumible bloqueado: El personaje está bajo evento de cansancio.")
		return

	# 2. Solo procesamos si el ítem es el energizante
	if id == "energizante":
		# Nivel 1 (+10), Nivel 2 (+20)
		var incremento: float = 10.0 * float(nivel)
		
		# Sumamos la energía asegurando que no pase de 100
		energia_actual = clamp(energia_actual + incremento, 0.0, 100.0)
		actualizar_interfaz()
		
		# Avisamos en el inventario
		var inv = get_tree().get_first_node_in_group("inventario")
		if inv and inv.has_method("mostrar_aviso"):
			inv.mostrar_aviso("+" + str(int(incremento)) + "% Energía")


# Mantener por compatibilidad si la señal sigue emitiéndose
func _on_decision_tomada(_fue_permitido: bool) -> void:
	pass


# Actualiza el nodo visual
func actualizar_interfaz() -> void:
	if barra_energia:
		barra_energia.value = clamp(energia_actual, 0.0, 100.0)
