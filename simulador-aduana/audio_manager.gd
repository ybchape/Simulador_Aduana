extends Node

const MUSICA_MENU = preload ("res://sounds/music_main_menu.mp3")
const MUSICA_GAMEPLAY = preload ("res://sounds/music_gameplay.wav")

var player_musica: AudioStreamPlayer

func _ready() -> void:
	# crea un reproductor de audio para la música de fondo
	player_musica = AudioStreamPlayer.new()
	add_child(player_musica)

	# Volumen más bajo que los efectos de sonido 
	player_musica.bus = "Master" 

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

func detener_musica() -> void:
	player_musica.stop()
