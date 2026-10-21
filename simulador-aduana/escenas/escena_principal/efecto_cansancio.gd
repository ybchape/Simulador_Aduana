extends ColorRect

var en_cansancio: bool = false
var tiempo_parpadeo: float = 0.0

func _ready() -> void:
	color.a = 0.0 # Totalmente transparente al inicio
	
	
	EventBus.cansancio_confirmado.connect(func(): en_cansancio = true)
	EventBus.evento_cansancio_finalizado.connect(_on_evento_finalizado)

func _on_evento_iniciado(_duracion: float) -> void:
	en_cansancio = true

func _on_evento_finalizado() -> void:
	en_cansancio = false
	# Restaura la pantalla normal con un tween 
	var tween = create_tween()
	tween.tween_property(self, "color:a", 0.0, 1.0)

func _process(delta: float) -> void:
	if en_cansancio:
		tiempo_parpadeo += delta * 2.0 # Velocidad del parpadeo
		# Usa sin() para generar un efecto suave de parpadeo/sueño
		var alfa_objetivo = (sin(tiempo_parpadeo) + 1.0) / 2.0
		# Limita para que la pantalla no se ponga 100% negra todo el tiempo (máximo 85% de oscuridad)
		color.a = lerp(color.a, alfa_objetivo * 0.85, delta * 3.0)
