extends TextureProgressBar

func _ready() -> void:
	max_value = 100.0
	value = 100.0
	
	# Escucha la señal del EventBus cuando cambia la energía
	if EventBus.has_signal("energia_cambiada"):
		EventBus.energia_cambiada.connect(_on_energia_cambiada)

func _on_energia_cambiada(nueva_energia: float) -> void:
	
	var tween = create_tween()
	tween.tween_property(self, "value", nueva_energia, 0.3).set_trans(Tween.TRANS_SINE)
