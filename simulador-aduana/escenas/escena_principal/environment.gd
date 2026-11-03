extends Node3D

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var directional_light: DirectionalLight3D = $DirectionalLight3D

var luz_original: float = 1.0
var ambiente_original: float = 1.0
var bg_original: float = 1.0

func _ready() -> void:
	# Guardamos la energía original de la luz direccional
	if directional_light:
		luz_original = directional_light.light_energy
		
	# Guardamos las energías del Environment
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		bg_original = env.background_energy_multiplier
		ambiente_original = env.ambient_light_energy

	# Escuchamos los eventos del EventBus
	EventBus.evento_corte_luz_iniciado.connect(_on_corte_luz_iniciado)
	EventBus.evento_corte_luz_finalizado.connect(_on_corte_luz_finalizado)

func _on_corte_luz_iniciado(_duracion: float, _costo: float) -> void:
	# Apaga/Oscurece la luz direccional al 5%
	if directional_light:
		directional_light.light_energy = 0.05
		
	# Reduce la iluminación ambiental al mínimo
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.background_energy_multiplier = 0.05
		env.ambient_light_energy = 0.05

func _on_corte_luz_finalizado() -> void:
	# Restablece la luz original cuando termina el evento
	if directional_light:
		directional_light.light_energy = luz_original
		
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.background_energy_multiplier = bg_original
		env.ambient_light_energy = ambiente_original
