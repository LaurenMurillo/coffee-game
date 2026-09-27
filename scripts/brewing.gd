extends Control
## Brewing scene: the player builds the drink the current customer ordered.
## Reads the order from GameState.current_recipe, scores the drink when served,
## hands the score to GameState.record_result(), then returns to the counter.
##
## Nodes this script needs (each one set to "Access as Unique Name"):
##   OrderReminder       (Label)          shows what the customer ordered
##   CupLabel            (Label)          shows what's in the cup so far
##   MilkOptions         (HBoxContainer)  milk buttons are created in here
##   SyrupOptions        (HBoxContainer)  syrup buttons are created in here
##   TemperatureOptions  (HBoxContainer)  hot/iced buttons are created in here
##   ServeButton         (Button)
##   ResetButton         (Button)

# --- Ingredient choices ---
# One button is made for each value. Every value your .tres files use must be
# listed here. Capitalization and extra spaces don't matter when comparing,
# and an empty field in a recipe counts as "none".
const MILK_OPTIONS: Array[String] = ["Moonmilk", "Frostmilk", "oat"]
const SYRUP_OPTIONS: Array[String] = ["Frostberry", "Amberglow", "caramel"]
const TEMPERATURE_OPTIONS: Array[String] = ["Hot", "Iced"]

# Each correct part (milk, syrup, temperature) is worth a third of 100 points.
const POINTS_PER_PART: float = 100.0 / 3.0

# --- The drink in progress (only exists while this scene is open) ---
var selected_milk: String = ""
var selected_syrup: String = ""
var selected_temperature: String = ""

# --- Node references ---
@onready var order_reminder: Label = %OrderReminder
@onready var cup_label: Label = %CupLabel
@onready var milk_options: HBoxContainer = %MilkOptions
@onready var syrup_options: HBoxContainer = %SyrupOptions
@onready var temperature_options: HBoxContainer = %Temperature
@onready var serve_button: Button = %ServeButton
@onready var reset_button: Button = %ResetButton


func _ready() -> void:
	build_option_buttons(milk_options, MILK_OPTIONS, _on_milk_chosen)
	build_option_buttons(syrup_options, SYRUP_OPTIONS, _on_syrup_chosen)
	build_option_buttons(temperature_options, TEMPERATURE_OPTIONS, _on_temperature_chosen)

	serve_button.pressed.connect(_on_serve_pressed)
	reset_button.pressed.connect(reset_cup)

	show_order()
	reset_cup()


# Creates one toggle button per option inside a container.
# The ButtonGroup makes them act like radio buttons: picking one un-picks the others.
func build_option_buttons(container: HBoxContainer, options: Array[String], on_chosen: Callable) -> void:
	var group := ButtonGroup.new()
	for option in options:
		var button := Button.new()
		button.text = option.capitalize()
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(on_chosen.bind(option))
		container.add_child(button)


# --- Showing the order and the cup ---

func show_order() -> void:
	var r: Recipe = GameState.current_recipe
	if r == null:
		# Happens if you run this scene directly with F6 instead of from the start screen.
		order_reminder.text = "No order. Start the game from the start screen."
		return
	order_reminder.text = "Order: %s\nMilk: %s   Syrup: %s   Temp: %s" % [
		r.recipe_name, r.milk, r.syrup, r.temperature
	]


func update_cup() -> void:
	cup_label.text = "In the cup:  Milk: %s   Syrup: %s   Temp: %s" % [
		display(selected_milk), display(selected_syrup), display(selected_temperature)
	]
	# Only allow serving once every part has been chosen and there is an order.
	serve_button.disabled = not is_cup_complete() or GameState.current_recipe == null


func reset_cup() -> void:
	selected_milk = ""
	selected_syrup = ""
	selected_temperature = ""
	for container in [milk_options, syrup_options, temperature_options]:
		for button in container.get_children():
			button.set_pressed_no_signal(false)
	update_cup()


func is_cup_complete() -> bool:
	return selected_milk != "" and selected_syrup != "" and selected_temperature != ""


func display(value: String) -> String:
	return "—" if value == "" else value.capitalize()


# --- Button handlers ---

func _on_milk_chosen(value: String) -> void:
	selected_milk = value
	update_cup()


func _on_syrup_chosen(value: String) -> void:
	selected_syrup = value
	update_cup()


func _on_temperature_chosen(value: String) -> void:
	selected_temperature = value
	update_cup()


func _on_serve_pressed() -> void:
	GameState.record_result(calculate_quality())
	get_tree().change_scene_to_file("res://scenes/counter.tscn")


# --- Scoring ---

# Returns 0, 33, 67 or 100 depending on how many parts match the order.
func calculate_quality() -> float:
	var r: Recipe = GameState.current_recipe
	var quality := 0.0
	if same(selected_milk, r.milk):
		quality += POINTS_PER_PART
	if same(selected_syrup, r.syrup):
		quality += POINTS_PER_PART
	if same(selected_temperature, r.temperature):
		quality += POINTS_PER_PART
	return roundf(quality)


# Compares two values ignoring capitalization and spaces; empty counts as "none".
func same(a: String, b: String) -> bool:
	return normalize(a) == normalize(b)


func normalize(value: String) -> String:
	var v := value.strip_edges().to_lower()
	return "none" if v == "" else v
