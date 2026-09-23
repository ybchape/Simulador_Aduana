extends Control

var se_puede_decidir = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.pedido_en_zona.connect(_actualizar_estado)

func _actualizar_estado(hay_pedido):
	se_puede_decidir = hay_pedido


func _on_btn_permitir_pressed() -> void:
	if se_puede_decidir == true:
		EventBus.decision_tomada.emit(true)
		se_puede_decidir = false
		print("¡Apretaste PERMITIR! La caja sigue su curso.")


func _on_btn_denegar_pressed() -> void:
	if se_puede_decidir == true:
		EventBus.decision_tomada.emit(false)
		se_puede_decidir = false
		print("¡Apretaste DENEGAR! La caja es rechazada.")
