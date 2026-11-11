class_name AudioManagerClass
extends Node

#musica
const MUSICA_MENU = preload ("res://sounds/main_menu/music_main_menu.mp3")
const MUSICA_GAMEPLAY = preload ("res://sounds/gameplay/music_gameplay.wav")

# efectos de sonido SFX
const SFX_ESCANER = preload("res://sounds/escaner/sound_escaner.mp3")
const SFX_CUTER = preload("res://sounds/cutter/sound_cutter.wav")
const SFX_CINTA = preload("res://sounds/cinta_transportadora/sound_cinta.wav")
# balanza 
# const SFX_BALANZA = preload

var player_musica: AudioStreamPlayer
var player_sfx: AudioStreamPlayer
var player_cinta: AudioStreamPlayer # reproductor en loop para la cinta

func _ready() -> void:
	# crea un reproductor de audio para la música de fondo
	player_musica = AudioStreamPlayer.new()
	player_musica.name = "PlayerMusica"
	player_musica.bus = "Musica"
	add_child(player_musica)

# reproductor de sfx cortos 
	player_sfx = AudioStreamPlayer.new()
	player_sfx.name = "PlayerSFX"
	player_sfx.bus = "Master" 
	add_child(player_sfx)

	# reproductor para la cinta en loop
	player_cinta = AudioStreamPlayer.new()
	player_cinta.name = "PlayerCinta"
	player_cinta.bus = "Master"
	player_cinta.volume_db = -12.0
	add_child(player_cinta)

	# Volumen más bajo que los efectos de sonido con el bus nuevo que cree
	#player_musica.bus = "Musica"  

	# inicia con la música del menú principal
	reproducir_musica_menu()

func reproducir_musica_menu() -> void:
	if player_musica.stream == MUSICA_MENU and player_musica.playing:
		return
	player_musica.stream = MUSICA_MENU
	player_musica.volume_db = -12.0 # VOLUMEN DEL MENU: AJUSTABLEEEEE
	player_musica.play()

func reproducir_musica_gameplay() -> void:
	if player_musica.stream == MUSICA_GAMEPLAY and player_musica.playing:
		return
	player_musica.stream = MUSICA_GAMEPLAY
	player_musica.volume_db = -14.0 # # VOLUMEN DEL GAMEPLAY: AJUSTABLEEEEE
	player_musica.play()

# func de sfx
func reproducir_escaner() -> void:
	player_sfx.stream = SFX_ESCANER
	player_sfx.play()

func reproducir_cutter() -> void:
	player_sfx.stream = SFX_CUTER
	player_sfx.play()

# controla el sonido de la cinta transportadora (loopo cuando se mueve)
func alternar_sonido_cinta(en_movimiento: bool) -> void:
	if en_movimiento:
		if player_cinta.stream != SFX_CINTA or not player_cinta.playing:
			player_cinta.stream = SFX_CINTA
			player_cinta.play()
	else:
		if player_cinta.playing:
			player_cinta.stop()

func detener_musica() -> void:
	player_musica.stop()
