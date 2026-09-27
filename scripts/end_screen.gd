extends Control

@onready var final_score_label: Label = $FinalScoreLabel
@onready var play_again_button: Button = $PlayAgainBtn

func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again_pressed)
	final_score_label.text = "Final Score: %d" % GameState.score

func _on_play_again_pressed() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/counter.tscn")
 
