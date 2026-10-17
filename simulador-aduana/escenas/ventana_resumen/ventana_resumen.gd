extends CanvasLayer


@onready var panel_container: PanelContainer = $PanelContainer
@onready var titulo: Label = $PanelContainer/VBoxContainer/Titulo
@onready var dinero_ganado: Label = $PanelContainer/VBoxContainer/DineroGanado
@onready var dinero_descontado: Label = $PanelContainer/VBoxContainer/DineroDescontado
@onready var total: Label = $PanelContainer/VBoxContainer/Total
@onready var siguiente_dia: Button = $PanelContainer/VBoxContainer/SiguienteDia

# var para guardar el neto del día actual 
var dinero_neto_actual: float = 0.0


func _ready() -> void:
	# Nos aseguramos de que inicie oculta
	hide()
	if panel_container:
		panel_container.hide()
	
	# Nos conectamos a la señal del EventBus
	EventBus.objetivo_dia_alcanzado.connect(_mostrar_resumen)
	
	# Conectamos el botón para reiniciar/avanzar
	if siguiente_dia:
		siguiente_dia.pressed.connect(_on_btn_siguiente_dia_pressed)

# --- NUEVO: Se asigna un valor por defecto al parámetro stats para poder tomarlo de GameManager si no se envía ---
func _mostrar_resumen(stats: Dictionary = {}) -> void:
	# --- NUEVO: Si no se enviaron stats desde EventBus, se consultan al GameManager ---
	if stats.is_empty() and GameManager:
		stats = GameManager.obtener_stats_resumen()

	# save el neto en la variable de la clase 
	dinero_neto_actual = stats.get("neto", 0.0)
	
	titulo.text = "RESUMEN DEL DÍA\nPedidos correctos: " + str(stats.get("correctos", 0)) + " / " + str(stats.get("total", 0))
	dinero_ganado.text = "Dinero obtenido: $" + str(stats.get("ganado", 0))
	dinero_descontado.text = "Dinero descontado: -$" + str(stats.get("descontado", 0))
	total.text = "Balance neto: $" + str(stats.get("neto", 0))

	# Mostrar la ventana inmediatamente

	show()
	if panel_container:
		panel_container.show()

	# Liberar el mouse para interactuar con el botón
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_btn_siguiente_dia_pressed() -> void:
	# El neto ya se acreditó al alcanzar la meta, antes de mostrar el resumen.
	# Aquí solo avanzamos el día para evitar acreditar el turno dos veces.
	if GameManager:
		GameManager.avanzar_siguiente_dia()

	# Reinicia la escena actual para simular el siguiente día
	get_tree().reload_current_scene()
