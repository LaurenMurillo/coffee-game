# This file runs the counter scene. 
# It's where customers arive, place an order, and then react to the drink
# this scene gets loaded two different ways:
# 1) customer arrives from start screen, or from next customer button press
# 2) player came from brew station so customer can react to drink

extends Control

# node references from Counter scene:
@onready var customer_sprite: TextureRect = $CustomerSprite
@onready var order_label: Label = $OrderLabel
@onready var reaction_label: Label = $ReactionLabel
@onready var score_label: Label = $ScoreLabel
@onready var start_brewing_button: Button = $StartBrewingButton
@onready var next_customer_button: Button = $NextCustomerButton
@onready var mute_button: Button = $MuteButton
@onready var drink_display: Control = $DrinkDisplay
@onready var drink_cup: TextureRect = $DrinkDisplay/DrinkCup
@onready var drink_liquid: TextureRect = $DrinkDisplay/DrinkLiquid

# Godot runs this automatically every time the counter scene loads 
func _ready() -> void:
	start_brewing_button.pressed.connect(_on_start_brewing_pressed)
	next_customer_button.pressed.connect(_on_next_customer_pressed)
	mute_button.pressed.connect(_on_mute_pressed)
	update_score()

	if GameState.awaiting_reaction:# by default awaiting_reaction set to false
		show_reaction()
	else:
		next_customer()# this should run first and once a button is pressed then we can change scene

#adds functionality to mute button
func _on_mute_pressed() -> void:
	MusicPlayer.toggle_mute()

#handles switching to new customer/ what happens when there's no more
func next_customer() -> void:
	drink_display.hide()
	reaction_label.text = ""
	next_customer_button.hide()
	# -- Handles different customer lineup 
	if GameState.start_new_customer():
		var r := GameState.current_recipe
		customer_sprite.texture = r.customer_sprite
		var order_text = "%s\nTemp: %s  Milk: %s  Syrup: %s" % [r.recipe_name, r.temperature, r.milk, r.syrup]
		type_text(order_label, r.order_line)
		start_brewing_button.show()
	# -- Triggers end scene when there's no more customers
	else:
		customer_sprite.texture = null
		start_brewing_button.hide()
		get_tree().change_scene_to_file("res://scenes/end_screen.tscn")


#grabs current customer and recipe name and reacts depending on saved quality
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
	drink_cup.texture = GameState.last_cup_texture
	drink_liquid.modulate = GameState.last_liquid_color
	drink_display.show()
	start_brewing_button.hide()
	next_customer_button.show()

# -- every time called score is updated (important for progress)
func update_score() -> void:
	score_label.text = "Score: %d " % [GameState.score]

#-- Handles pretty text display to slowly show as typed
func type_text(label: Label, text: String, speed: float = 0.03) -> void:
	label.text = text
	label.visible_characters = 0
	for i in text.length():
		label.visible_characters = i + 1
		await get_tree().create_timer(speed).timeout
	

#start brewing btn's function to switch to brewing scene
func _on_start_brewing_pressed() -> void:
	MusicPlayer.play_click()
	get_tree().change_scene_to_file("res://scenes/brewing.tscn")


#next customer btn function to switch to next recipe/customer
func _on_next_customer_pressed() -> void:
	# -- Prepares reaction for next customer
	MusicPlayer.play_click()
	GameState.awaiting_reaction = false
	next_customer()
