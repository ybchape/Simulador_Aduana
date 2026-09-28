extends CanvasLayer


@onready var panel_container: PanelContainer = $PanelContainer
@onready var titulo: Label = $PanelContainer/VBoxContainer/Titulo
@onready var dinero_ganado: Label = $PanelContainer/VBoxContainer/DineroGanado
@onready var dinero_descontado: Label = $PanelContainer/VBoxContainer/DineroDescontado
@onready var total: Label = $PanelContainer/VBoxContainer/Total
@onready var siguiente_dia: Button = $PanelContainer/VBoxContainer/SiguienteDia


func _ready() -> void:
	# Nos aseguramos de que inicie oculta
	hide()
	
	# Nos conectamos a la señal del EventBus
	EventBus.objetivo_dia_alcanzado.connect(_mostrar_resumen)
	
	# Conectamos el botón para reiniciar/avanzar
	if siguiente_dia:
		siguiente_dia.pressed.connect(_on_btn_siguiente_dia_pressed)

func _mostrar_resumen(stats: Dictionary) -> void:
	titulo.text = "RESUMEN DEL DÍA (" + str(stats.correctos) + "/" + str(stats.total) + ")"
	dinero_ganado.text = "Dinero obtenido: $" + str(stats.ganado)
	dinero_descontado.text = "Dinero descontado: -$" + str(stats.descontado)
	total.text = "Balance neto: $" + str(stats.neto)
	
	
	
	# Mostrar la ventana inmediatamente
	show()
	
	# Liberar el mouse para interactuar con el botón
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_btn_siguiente_dia_pressed() -> void:
	# Reinicia la escena actual para simular el siguiente día
	get_tree().reload_current_scene()
