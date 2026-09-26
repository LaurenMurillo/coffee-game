extends Control

@onready var customer_sprite: TextureRect = $CustomerSprite
@onready var order_label: Label = $OrderLabel
@onready var reaction_label: Label = $ReactionLabel
@onready var score_label: Label = $ScoreLabel
@onready var start_brewing_button: Button = $StartBrewingButton
@onready var next_customer_button: Button = $NextCustomerButton


func _ready() -> void:
	start_brewing_button.pressed.connect(_on_start_brewing_pressed)
	next_customer_button.pressed.connect(_on_next_customer_pressed)
	update_score()

	if GameState.awaiting_reaction:
		show_reaction()
	else:
		next_customer()


func next_customer() -> void:
	reaction_label.text = ""
	next_customer_button.hide()
	if GameState.start_new_customer():
		var r := GameState.current_recipe
		customer_sprite.texture = r.customer_sprite
		var order_text = "%s\nMilk: %s  Syrup: %s  %s" % [r.recipe_name, r.milk, r.syrup, r.temperature]
		type_text(order_label, order_text)
		start_brewing_button.show()
	else:
		customer_sprite.texture = null
		order_label.text = "That's all for today!"
		start_brewing_button.hide()


func show_reaction() -> void:
	GameState.awaiting_reaction = false
	customer_sprite.texture = GameState.current_recipe.customer_sprite
	order_label.text = GameState.current_recipe.recipe_name
	var q := GameState.last_quality
	if q >= 90:
		reaction_label.text = "Perfect!"
	elif q >= 60:
		reaction_label.text = "Not bad."
	else:
		reaction_label.text = "This isn't what I ordered..."
		update_score()
	start_brewing_button.hide()
	next_customer_button.show()


func update_score() -> void:
	score_label.text = "Score: %d " % [GameState.score]


func type_text(label: Label, text: String, speed: float = 0.03) -> void:
	label.text = text
	label.visible_characters = 0
	for i in text.length():
		label.visible_characters = i + 1
		await get_tree().create_timer(speed).timeout
	

func _on_start_brewing_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/brewing.tscn")


func _on_next_customer_pressed() -> void:
	# -- Prepares reaction for next customer
	GameState.awaiting_reaction = false
	next_customer()
