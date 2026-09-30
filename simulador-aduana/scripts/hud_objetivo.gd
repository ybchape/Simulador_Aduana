extends CanvasLayer

@onready var barra_progreso: TextureProgressBar = $Barra_Progreso
@onready var label_texto: Label = $Label_Texto

func _ready() -> void:
	# SE conecta a los eventos del EventBus
	EventBus.progreso_dia_actualizado.connect(_actualizar_progreso)
	EventBus.objetivo_dia_alcanzado.connect(_on_objetivo_alcanzado)

func _actualizar_progreso(actual: int, meta: int) -> void:
	if barra_progreso:
		barra_progreso.max_value = meta
		barra_progreso.value = actual

	if label_texto:
		label_texto.text = "Pedidos: " + str(actual) + " / " + str(meta)

func _on_objetivo_alcanzado(_stats: Dictionary = {}) -> void:
	if label_texto:
		label_texto.text = "¡JORNADA COMPLETADA!"
