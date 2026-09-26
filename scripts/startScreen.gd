extends Control

@onready var play_button: Button = %PlayButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)


func _on_play_button_pressed() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/counter.tscn")
