extends Node

@export var tiempo_min_duracion: float = 30.0
@export var tiempo_max_duracion: float = 40.0
@export var costo_reparacion_luz: float = 150.0

# Lista de todos los eventos aleatorios posibles 
const EVENTOS_POSIBLES: Array[String] = ["cansancio", "alta_demanda", "corte_luz", "sueno"]


var esta_cansado: bool = false
var esta_alta_demanda: bool = false
var esta_corte_luz: bool = false
var esta_sueno: bool = false
var timer_corte_luz: SceneTreeTimer = null

func _ready() -> void:
#  Si estamos en el Día 1, NUNCA se activa el evento de cansancio
	if GameManager and GameManager.dia_actual <= 1:
		print("Día 1: Día de tutorial, sin eventos aleatorios.")
		return

# Escuchar si se paga la reparación de luz
	if not EventBus.pagar_reparacion_corte_luz.is_connected(_on_pagar_reparacion_luz):
		EventBus.pagar_reparacion_corte_luz.connect(_on_pagar_reparacion_luz)

	# Elegir UN SOLO evento para el día de hoy
	seleccionar_evento_del_dia()

	#  Probabilidad del 60% de que ocurra en los días 2 en adelante
	#if randf() < 0.6:
		# Se dispara aleatoriamente entre el segundo 15 y el 45 del día
		#var tiempo_aleatorio = randf_range(15.0, 45.0)
		#get_tree().create_timer(tiempo_aleatorio).timeout.connect(disparar_evento_cansancio)

# Evento de ALTA DEMANDA (randi)
	#if GameManager and GameManager.dia_actual <= 1:
		#print ("Día 1: Evento de alta demanda desactivado.")
	#else:
			# Probability 50% a partir del dia 2 de que se ejecute evento de alta demanda
			#if randf() < 0.5:
				#var tiempo_aleatorio_demanda = randf_range(10.0, 40.0)
				#var timer_demanda = get_tree().create_timer(tiempo_aleatorio_demanda)
				#timer_demanda.timeout.connect(disparar_alta_demanda)

#  Evento Corte de Luz 
	#if randf() < 0.4:
		#var tiempo_aleatorio_luz = randf_range(12.0, 35.0)
		#get_tree().create_timer(tiempo_aleatorio_luz).timeout.connect(disparar_corte_luz)

	# Escuchar si el jugador paga la reparación durante el corte de luz
	#EventBus.pagar_reparacion_corte_luz.connect(_on_pagar_reparacion_luz)

func seleccionar_evento_del_dia() -> void:
	# Filtrar solo los eventos que NO hayan salido todavía en esta partida
	var eventos_disponibles: Array[String] = []
	for ev in EVENTOS_POSIBLES:
		if not GameManager.eventos_usados.has(ev):
			eventos_disponibles.append(ev)

	# Si ya salieron todos los eventos en la partida, reiniciamos la lista disponible
	if eventos_disponibles.is_empty():
		GameManager.eventos_usados.clear()
		eventos_disponibles = EVENTOS_POSIBLES.duplicate()

	# Elegir un evento al azar de los disponibles
	var evento_elegido: String = eventos_disponibles.pick_random()
	GameManager.eventos_usados.append(evento_elegido)
	
	print("Día ", GameManager.dia_actual, " - Evento asignado: ", evento_elegido)
	
	# El evento de sueño ocurre AL INICIO del día (segundo 1.0)
	# Los otros ocurren a mitad de la jornada (entre 15 y 35s)
	if evento_elegido == "sueno":
		get_tree().create_timer(1.0).timeout.connect(disparar_evento_sueno)
	else:
		var tiempo_aleatorio: float = randf_range(15.0, 35.0)
		match evento_elegido:
			"cansancio":
				get_tree().create_timer(tiempo_aleatorio).timeout.connect(disparar_evento_cansancio)
			"alta_demanda":
				get_tree().create_timer(tiempo_aleatorio).timeout.connect(disparar_alta_demanda)
			"corte_luz":
				get_tree().create_timer(tiempo_aleatorio).timeout.connect(disparar_corte_luz)
	
# --- NUEVO EVENTO: SUEÑO ---
func disparar_evento_sueno() -> void:
	print("¡EVENTO SUEÑO PROGRAMADO! Mostrando cartel...")
	
	# Llama al cartel que creaste
	EventBus.evento_sueno_iniciado.emit()
	
	# Espera a que el jugador cierre el cartel clickeando en OK
	await EventBus.sueno_confirmado
	
	esta_sueno = true
	print("El personaje arrancó con sueño.")
	
	# A diferencia de los otros, el sueño dura TODO el turno.
	# No hay timer de finalización. Se reinicia solo al pasar de día.


func disparar_evento_cansancio() -> void:
	var duracion_evento = randf_range(tiempo_min_duracion, tiempo_max_duracion)
	print("¡EVENTO DE CANSANCIO PROGRAMADO! Mostrando cartel...")
	
	# MUESTRA el cartel
	EventBus.evento_cansancio_iniciado.emit(duracion_evento)
	
	# Espera a que el jugador cierre el cartel
	await EventBus.cansancio_confirmado
	
	# Activar la lentitud y el parpadeo
	esta_cansado = true
	
	# Timer para finalizar la crisis
	await get_tree().create_timer(duracion_evento).timeout
	
	esta_cansado = false
	print("El evento de cansancio ha finalizado.")
	EventBus.evento_cansancio_finalizado.emit()

func disparar_alta_demanda() -> void:
	var duracion_demanda = randf_range(tiempo_min_duracion, tiempo_max_duracion)
	print ("Evento ALTA DEMANDA activado. Aumenta el flujo de pedidos")
# Muestra el cartel emitiendo la señal de inicio
	EventBus.evento_alta_demanda_iniciado.emit(duracion_demanda)

	# wait a que se cierre el cartel  en OK
	await EventBus.alta_demanda_confirmada

	esta_alta_demanda = true
	print("Evento ALTA DEMANDA activado. Aumenta el flujo de pedidos")
	EventBus.evento_alta_demanda_iniciado.emit(duracion_demanda) 

	# timer de la duración del evento
	await get_tree().create_timer(duracion_demanda).timeout

	esta_alta_demanda = false
	print("El evento de ALTA DEMANDA finalizó.")
	EventBus.evento_alta_demanda_finalizado.emit()

	# emite señal para que el spawner aclere y se muestra indicador visual y sonoro
	EventBus.evento_alta_demanda_iniciado.emit(duracion_demanda)

	# timer
	await get_tree().create_timer(duracion_demanda).timeout

	esta_alta_demanda = false
	print ("El evento de ALTA DEMANDA finalizó.")
	EventBus.evento_alta_demanda_finalizado.emit()
	
#  Lógica del Corte de Luz 
func disparar_corte_luz() -> void:
	var duracion_corte = randf_range(tiempo_min_duracion, tiempo_max_duracion)
	print("¡EVENTO CORTE DE LUZ INICIADO!")
	
	EventBus.evento_corte_luz_iniciado.emit(duracion_corte, costo_reparacion_luz)
	
	await EventBus.corte_luz_confirmado
	esta_corte_luz = true
	
	# Guarda referencia del timer para poder cancelarlo si paga la reparación
	timer_corte_luz = get_tree().create_timer(duracion_corte)
	
	await timer_corte_luz.timeout
	if esta_corte_luz:
		finalizar_corte_luz()


func _on_pagar_reparacion_luz() -> void:
	if not esta_corte_luz:
		return
		
	if EventBus.gastar_dinero(costo_reparacion_luz):
		print("Reparación de luz pagada ($", costo_reparacion_luz, "). Restableciendo energía...")
		finalizar_corte_luz()
	else:
		print("No tenés suficiente dinero para reparar la luz.")


func finalizar_corte_luz() -> void:
	esta_corte_luz = false
	print("El evento de corte de luz finalizó.")
	EventBus.evento_corte_luz_finalizado.emit()
