extends Control

var se_puede_decidir = false

@export var sonido_aceptar: AudioStream = preload ("res://sounds/buttons/button_aprobado.wav")
@export var sonido_denegar: AudioStream = preload ("res://sounds/buttons/button_denegado.wav")

# Reproductor interno para los clics de botones
var sfx_player: AudioStreamPlayer 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.pedido_en_zona.connect(_actualizar_estado)

	# asegura que tengamos el reproductor de audio OK
	if not has_node("AudioStreamPlayer"):
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "AudioStreamPlayer"
		sfx_player.bus = "Master" 
		add_child(sfx_player)
	else:
		sfx_player = $AudioStreamPlayer

# Oscurece y hunde cada botón mientras se mantiene presionado
	for btn: TextureButton in [$TextureRect/HBoxContainer/BtnPermitir, $TextureRect/HBoxContainer/BtnDenegar]:
		btn.button_down.connect(func():
			btn.self_modulate = Color(0.55, 0.55, 0.55)
			btn.position.y += 3.0
		)
		btn.button_up.connect(func():
			btn.self_modulate = Color.WHITE
			btn.position.y -= 3.0
		)

func _actualizar_estado(hay_pedido):
	se_puede_decidir = hay_pedido


func _on_btn_permitir_pressed() -> void:
	if se_puede_decidir == true:
		# reproduce sonido de aprobación
		if sonido_aceptar:
			sfx_player.stream = sonido_aceptar
			sfx_player.play()

# Efectos visuales: rebote en el botón y destello verde en la caja
		var btn: Control = find_child("*permitir*", true, false) as Control
		_animar_boton_ui(btn)
		_destello_decision_3d(true)

		# desaparece la herramienta cuando se toma la decision
		EventBus.decision_tomada.emit(true)
		se_puede_decidir = false
		print("¡Apretaste PERMITIR! La caja sigue su curso.")
		EventBus.herramienta_seleccionada.emit("")

func _on_btn_denegar_pressed() -> void:
	if se_puede_decidir == true:
		# reproduce sonido denegado
		if sonido_denegar:
			sfx_player.stream = sonido_denegar
			sfx_player.play()

# Efectos visuales: rebote en el botón y destello rojo en la caja
		var btn: Control = find_child("*denegar*", true, false) as Control
		_animar_boton_ui(btn)
		_destello_decision_3d(false)

		# desaparece la herramienta cuando se toma la decision
		EventBus.decision_tomada.emit(false)
		se_puede_decidir = false
		print("¡Apretaste DENEGAR! La caja es rechazada.")
		EventBus.herramienta_seleccionada.emit("")

func _animar_boton_ui(boton: Control) -> void:
	if not boton:
		return
	boton.pivot_offset = boton.size / 2.0
	# Destello blanco brillante (HDR modulate) + rebote de escala
	boton.modulate = Color(1.8, 1.8, 1.8, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(boton, "scale", Vector2(0.85, 0.85), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(boton, "modulate", Color.WHITE, 0.18)
	tween.tween_property(boton, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _destello_decision_3d(es_aprobado: bool) -> void:
	var escena: Node = get_tree().current_scene
	if not escena:
		return
	var luz: OmniLight3D = escena.find_child("LuzDecision", true, false) as OmniLight3D
	if not luz:
		return
	luz.light_color = Color(0.2, 1.0, 0.3) if es_aprobado else Color(1.0, 0.2, 0.2)
	luz.light_energy = 6.0
	luz.visible = true
	
	var tween: Tween = create_tween()
	tween.tween_property(luz, "light_energy", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	if is_instance_valid(luz):
		luz.visible = false
