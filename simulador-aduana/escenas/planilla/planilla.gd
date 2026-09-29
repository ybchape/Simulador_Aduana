extends Control

@onready var lbl_producto: Label = $MarginContainer/VBoxContainer/LblProducto
@onready var lbl_peso: Label = $MarginContainer/VBoxContainer/LblPeso
@onready var lbl_codigo: Label = $MarginContainer/VBoxContainer/LblCodigo

#variables para la interaccion con la planilla (tween)
var escala_original: Vector2 = Vector2.ONE
var escala_zoom: Vector2 = Vector2(1.1, 1.1)
var tween: Tween

func _ready() -> void:
	escala_original = scale
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# función principal para alimentar la planilla con un pedido info func
func cargar_pedido(datos: PedidoInfo) -> void:
	if datos == null:
		print("Advertencia: No se recibieron datos de pedido.")
		return

	lbl_producto.text = "Producto: " + datos.nombre_producto
	lbl_peso.text = "Peso: " + str(datos.peso_kg) + " kg"
	lbl_codigo.text = "Código: " + datos.codigo_identificador

# funciones para la animación
func _on_mouse_entered() -> void:
	_animar_escala(escala_zoom)

func _on_mouse_exited() -> void:
	_animar_escala(escala_original)

func _animar_escala(objetivo: Vector2) -> void:
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", objetivo, 0.2)
