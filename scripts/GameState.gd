extends Node

var score: int = 0

# --- Settings ---
# this variable was meant to set how many customers to generate
# we are currently just going to loop through our customer_queue array
const CUSTOMERS_PER_DAY: int = 8

# -- current customer and order tracking ---
#The counter sets it, 
#the brewing scene checks the player's drink against it, 
#then the counter uses it again to show the reaction
var current_recipe: Recipe

# drinks that can be ordered
var customer_queue: Array[Recipe] = [
	preload("res://resources/recipes/frost_bite.tres"),
	preload("res://resources/recipes/warmHug.tres"),
]

var queue_index: int = 0

# -- transition betweeen counter scene and actual brewing scene
var awaiting_reaction: bool = false
var last_quality: float = 100.0

func _ready() -> void:
	reset_game()
	
# Moves to the next customer. Returns false when the day is over.
func start_new_customer() -> bool:
	if not has_more_customers():
		return false
	current_recipe = customer_queue[queue_index]
	queue_index += 1
	return true

func has_more_customers() -> bool:
	return queue_index < customer_queue.size()
	
# changes our score
func record_result(quality: float) -> void:
	last_quality = quality
	awaiting_reaction = true
	score += int(quality)
	

func reset_game():
	score = 0
	queue_index = 0
	awaiting_reaction = false
