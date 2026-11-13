extends CanvasLayer


@onready var panel_container: PanelContainer = $PanelContainer
@onready var titulo: Label = $PanelContainer/VBoxContainer/Titulo
@onready var dinero_ganado: Label = $PanelContainer/VBoxContainer/DineroGanado
@onready var dinero_descontado: Label = $PanelContainer/VBoxContainer/DineroDescontado
@onready var total: Label = $PanelContainer/VBoxContainer/Total
@onready var siguiente_dia: Button = $PanelContainer/VBoxContainer/SiguienteDia

@onready var bono_evento: Label = $PanelContainer/VBoxContainer/BonoEvento


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

func _mostrar_resumen(stats: Dictionary) -> void:
	# save el neto en la variable de la clase 
	dinero_neto_actual = stats.neto
	
	# Liquidamos el neto de hoy en la billetera principal
	if GameManager:
		GameManager.liquidar_dia()
	
	titulo.text = "RESUMEN DEL DÍA\nPedidos correctos: " + str(stats.correctos) + " / " + str(stats.total)
	dinero_ganado.text = "Dinero obtenido: $" + str(stats.ganado)
	dinero_descontado.text = "Dinero descontado: -$" + str(stats.descontado)
	total.text = "Balance neto: $" + str(stats.neto)

# --- NUEVO: Lógica para mostrar u ocultar el bono ---
	if stats.has("hubo_evento") and stats.hubo_evento == true:
		bono_evento.show()
		
		if stats.errores_evento == 0:
			# Si no hubo errores, muestra el bono en verde
			bono_evento.text = "Bono por Evento Perfecto: +$" + str(stats.bono_evento)
			bono_evento.modulate = Color("2ecc71") 
		else:
			# Si hubo 1 o más errores, te avisa que lo perdiste en rojo
			bono_evento.text = "Perdiste el bono por equivocarte"
			bono_evento.modulate = Color("e74c3c") 
	else:
		bono_evento.hide()
	# ----------------------------------------------------

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
