extends Node

var score: int = 0
var combo: int = 0

# -- current customer and order tracking ---
var current_recipe: Recipe
var customer_queue: Array[Recipe] = []
var queue_index: int = 0

# -- transition betweeen counter scene and actual brewing scene
var awaiting_reaction: bool = false
var last_quality: float = 100.0

func start_new_customer():
	current_recipe = customer_queue[queue_index]
	queue_index += 1

func has_more_customers() -> bool:
	return queue_index < customer_queue.size()
	

func reset_game():
	score = 0
	combo = 0
	queue_index = 0
	awaiting_reaction = false
