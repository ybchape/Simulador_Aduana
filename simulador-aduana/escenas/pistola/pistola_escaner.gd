extends Node3D

@onready var luz_roja: SpotLight3D = $LuzRoja
@onready var rayo_laser: MeshInstance3D = get_node_or_null("RayoLaser")

func _ready() -> void:
	if luz_roja:
		luz_roja.visible = false
	if rayo_laser:
		rayo_laser.visible = false
	
	# Se dispara exactamente cuando el jugador escanea una caja
	EventBus.escanear_objeto.connect(_activar_efecto_escaneo)

func _activar_efecto_escaneo(_forma: Mesh) -> void:
	# Busca la caja detenida en la cinta y apunta la luz directo hacia ella
	var caja_objetivo: Node3D = _obtener_caja_actual()
	if caja_objetivo:
		var centro_caja: Vector3 = caja_objetivo.global_position + Vector3(0, 0.25, 0)
		if luz_roja:
			luz_roja.look_at(centro_caja, Vector3.UP)
		if rayo_laser:
			rayo_laser.look_at(centro_caja, Vector3.UP)

	if luz_roja:
		luz_roja.visible = true
		luz_roja.light_energy = 0.0
	if rayo_laser:
		rayo_laser.visible = true

	var tween: Tween = create_tween()
	if luz_roja:
		tween.tween_property(luz_roja, "light_energy", 12.0, 0.15)
		tween.tween_property(luz_roja, "light_energy", 4.0, 0.15)
		tween.tween_property(luz_roja, "light_energy", 12.0, 0.20)
		tween.tween_property(luz_roja, "light_energy", 0.0, 0.20)
	else:
		tween.tween_interval(0.7)

	await tween.finished
	if is_instance_valid(luz_roja):
		luz_roja.visible = false
	if is_instance_valid(rayo_laser):
		rayo_laser.visible = false

func _obtener_caja_actual() -> Node3D:
	var escena: Node = get_tree().current_scene
	if not escena:
		return null
	var cinta: Node = escena.get_node_or_null("Espacio_Trabajo/CintaTransportadora")
	if cinta:
		return cinta.get("caja_actual") as Node3D
	return null
