extends ColorRect


@export var intervalo_bostezo: float = 6.0 # Segundos entre cada bostezo
var en_cansancio: bool = false
var tiempo_parpadeo: float = 0.0
var en_energia_critica: bool = false
var timer_bostezo: float = 0.0

func _ready() -> void:
	color.a = 0.0 # Totalmente transparente al inicio
	
	
	EventBus.cansancio_confirmado.connect(func(): en_cansancio = true)
	EventBus.evento_cansancio_finalizado.connect(_on_evento_finalizado)
	EventBus.energia_critica_cambiada.connect(_on_energia_critica_cambiada)

func _on_evento_iniciado(_duracion: float) -> void:
	en_cansancio = true

func _on_evento_finalizado() -> void:
	en_cansancio = false
	_verificar_restaurar_pantalla()

func _on_energia_critica_cambiada(esta_critica: bool) -> void:
	en_energia_critica = esta_critica
	if esta_critica:
		# Reproduce el bostezo
		AudioManager.reproducir_sueno()
		timer_bostezo = intervalo_bostezo
	else:
		timer_bostezo = 0.0
		_verificar_restaurar_pantalla()

func _verificar_restaurar_pantalla() -> void:
	# Solo aclara la pantalla si NO queda ninguno de los dos estados activo
	if not en_cansancio and not en_energia_critica:
		var tween = create_tween()
		tween.tween_property(self, "color:a", 0.0, 1.0)


func _process(delta: float) -> void:
	if en_cansancio or en_energia_critica:
		tiempo_parpadeo += delta * 2.0 # Velocidad del parpadeo
		# Usa sin() para generar un efecto suave de parpadeo/sueño
		var alfa_objetivo = (sin(tiempo_parpadeo) + 1.0) / 2.0
		# Limita para que la pantalla no se ponga 100% negra todo el tiempo (máximo 85% de oscuridad)
		color.a = lerp(color.a, alfa_objetivo * 0.85, delta * 3.0)
# Repite el bostezo cada X segundos mientras siga en energía crítica
	if en_energia_critica:
		timer_bostezo -= delta
		if timer_bostezo <= 0.0:
			AudioManager.reproducir_sueno()
			timer_bostezo = intervalo_bostezo
