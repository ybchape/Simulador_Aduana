extends Control


@export var pasos: Array[Dictionary] = [
	{
		"titulo": "¡BIENVENIDO AL PUESTO!",
		"texto": "Tu objetivo es verificar cada pedido que llega por la cinta transportadora. Compara los datos del ticket con la planilla."
	},
	{
		"titulo": "HERRAMIENTAS INICIALES",
		"texto": "• ESCÁNER: Muestra la imagen de Rayos X (usos limitados por turno).\n• CÚTER: Abre la caja para inspección manual (descuenta $20 por uso)."
	},
	{
		"titulo": "CONTRABANDO Y ERRORES",
		"texto": "Detectá objetos ilegales y denegales el paso. Si te equivocas 3 veces, quedarás despedido."
	},
	{
		"titulo": "¡A TRABAJAR!",
		"texto": "Usa los botones PERMITIR o DENEGAR. Completa los 3 pedidos de hoy para superar tu primer turno y acceder a la tienda."
	}
]

var paso_actual: int = 0

@onready var titulo_label = $PanelContainer/VBoxContainer/Titulo
@onready var texto_label = $PanelContainer/VBoxContainer/TextoExplicativo
@onready var paginador_label = $PanelContainer/VBoxContainer/HBoxBotones/IndicadorPaginas
@onready var btn_anterior = $PanelContainer/VBoxContainer/HBoxBotones/BotonAnterior
@onready var btn_siguiente = $PanelContainer/VBoxContainer/HBoxBotones/BotonSiguiente

func _ready():
	actualizar_paso()

func actualizar_paso():
	var datos = pasos[paso_actual]
	titulo_label.text = datos["titulo"]
	
	# Si TextoExplicativo es RichTextLabel:
	texto_label.text = datos["texto"]
	
	paginador_label.text = str(paso_actual + 1) + " / " + str(pasos.size())
	
	btn_anterior.disabled = (paso_actual == 0)
	
	if paso_actual == pasos.size() - 1:
		btn_siguiente.text = "¡Entendido!"
	else:
		btn_siguiente.text = "Siguiente >"

func _on_boton_siguiente_pressed() -> void:
	if paso_actual < pasos.size() - 1:
		paso_actual += 1
		actualizar_paso()
	else:
		_ir_a_escena_principal()

func _on_boton_anterior_pressed() -> void:
	if paso_actual > 0:
		paso_actual -= 1
		actualizar_paso()


func _on_boton_omitir_pressed() -> void:
	_ir_a_escena_principal()

func _ir_a_escena_principal() -> void:
	# Cambia a la escena de la aduana para empezar a jugar
	get_tree().change_scene_to_file("res://escenas/escena_principal/escena_principal.tscn")
