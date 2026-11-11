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

func _actualizar_estado(hay_pedido):
	se_puede_decidir = hay_pedido


func _on_btn_permitir_pressed() -> void:
	if se_puede_decidir == true:
		# reproduce sonido de aprobación
		if sonido_aceptar:
			sfx_player.stream = sonido_aceptar
			sfx_player.play()

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

		# desaparece la herramienta cuando se toma la decision
		EventBus.decision_tomada.emit(false)
		se_puede_decidir = false
		print("¡Apretaste DENEGAR! La caja es rechazada.")
		EventBus.herramienta_seleccionada.emit("")
