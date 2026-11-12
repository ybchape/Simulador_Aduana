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
	if luz_roja:
		luz_roja.visible = true
		luz_roja.light_energy = 8.0
	if rayo_laser:
		rayo_laser.visible = true

	# Animación de barrido/parpadeo láser durante 0.9 segundos (justo antes de que suba la pantalla)
	var tween: Tween = create_tween()
	if luz_roja:
		tween.tween_property(luz_roja, "light_energy", 2.0, 0.12)
		tween.tween_property(luz_roja, "light_energy", 8.0, 0.12)
	if rayo_laser:
		# Hace que el rayo haga un barrido vertical corto sobre la caja
		var rot_original: float = rotation_degrees.x
		tween.tween_property(self, "rotation_degrees:x", rot_original - 10.0, 0.25)
		tween.tween_property(self, "rotation_degrees:x", rot_original + 10.0, 0.35)
		tween.tween_property(self, "rotation_degrees:x", rot_original, 0.2)

	await tween.finished
	if is_instance_valid(luz_roja):
		luz_roja.visible = false
	if is_instance_valid(rayo_laser):
		rayo_laser.visible = false
