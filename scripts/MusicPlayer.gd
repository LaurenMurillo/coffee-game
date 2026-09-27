extends Node

@onready var sfx_player := AudioStreamPlayer.new()
@onready var player := AudioStreamPlayer.new()
var is_muted: bool = false

func _ready() -> void:
	add_child(player)
	player.stream = load("res://assets/music/bg_music.ogg")
	player.volume_db = 0
	player.play()
	
func toggle_mute() -> void:
	is_muted = not is_muted
	player.volume_db = -80 if is_muted else 0

func play_click() -> void:
	sfx_player.stream = load("res://assets/music/sfx_click.ogg")
	sfx_player.play()
