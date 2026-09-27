extends Control
## Brewing scene: the player builds the drink the current customer ordered,
## one station at a time:
##   1. Temperature: pick a hot or iced cup (the other cup disappears)
##   2. Milk:        milk station slides in; pick a milk
##   3. Syrup:       milk station slides out, syrup station slides in; pick a syrup
##   4. Serve:       Serve button appears
## Reads the order from GameState.current_recipe, scores the drink when served,
## hands the score to GameState.record_result(), then returns to the counter.
##
## Nodes (each one set to "Access as Unique Name"):
##   OrderReminder   (Label)          shows what the customer ordered
##   CupLabel        (Label)          shows what's in the cup so far
##   Temperature     (HBoxContainer)  hot/iced buttons are created in here
##   MilkStation     (VBoxContainer)  holds MilkOptions, slides in/out
##     MilkOptions   (HBoxContainer)  milk buttons are created in here
##   SyrupStation    (VBoxContainer)  holds SyrupOptions, slides in
##     SyrupOptions  (HBoxContainer)  syrup buttons are created in here
##   ServeButton     (Button)
##   ResetButton     (Button)

# --- Ingredient choices ---
# One button is made for each value. Every value the .tres files use must be
# listed here. 
const MILK_OPTIONS: Array[String] = ["Moonmilk", "Frostmilk", "Starlight foam", "Embercream"]
const SYRUP_OPTIONS: Array[String] = ["Frostberry", "Amberglow", "Cinderspice", "Bittersap"]
const TEMPERATURE_OPTIONS: Array[String] = ["Hot", "Iced"]

# --- Scoring ---
# Each correct part (temperature, milk, syrup) is worth a third of 100 points.
const POINTS_PER_PART: float = 100.0 / 3.0
const MISSED_AMOUNT_MULTIPLIER: float = 0.5   # right ingredient, amount outside the green

# --- Station animation ---
const SLIDE_TIME: float = 0.4   # seconds for a station to slide in or out
const POUR_RESULT_DELAY: float = 1.0   # seconds to show where the bar stopped before moving on

# --- Which station the player is on ---
enum Stage { TEMPERATURE, MILK, SYRUP, READY }
var stage: Stage = Stage.TEMPERATURE

# --- The drink in progress (only exists while this scene is open) ---
var selected_temperature: String = ""
var selected_milk: String = ""
var selected_syrup: String = ""

# milk bar variables:
var milk_poured: bool = false       # has the player stopped the milk bar yet?
var milk_in_green: bool = false     # did it stop inside the green zone?

# syrup bar variables:
var syrup_poured: bool = false
var syrup_in_green: bool = false

# Where each station sits in the editor, and its running slide animation.
var home_positions: Dictionary = {}
var slide_tweens: Dictionary = {}

# --- Node references ---
@onready var order_reminder: Label = %OrderReminder
@onready var cup_label: Label = %CupLabel
@onready var temperature_options: HBoxContainer = %Temperature
@onready var milk_station: Control = %MilkStation
@onready var milk_options: HBoxContainer = %MilkOptions
@onready var milk_bar: TimingBar = %MilkBar
@onready var syrup_bar: TimingBar = %SyrupBar
@onready var syrup_station: Control = %SyrupStation
@onready var syrup_options: HBoxContainer = %SyrupOptions
@onready var serve_button: Button = %ServeButton

#cyn-- syrups/temp sprites imported
@onready var frostberry_button: TextureButton = %SyrupOptions/FrostberryButton/Icon
@onready var amberglow_button: TextureButton = %SyrupOptions/AmberglowButton/Icon
@onready var cinderspice_button: TextureButton = %SyrupOptions/CinderspiceButton/Icon
@onready var bittersap_button: TextureButton = %SyrupOptions/BittersapButton/Icon
@onready var hot_button: TextureButton = %Temperature/HotButton/Icon
@onready var iced_button: TextureButton = %Temperature/IcedButton/Icon


func _ready() -> void:
	build_option_buttons(milk_options, MILK_OPTIONS, _on_milk_chosen)

	# stations slide back to where they were placed in the editor
	home_positions[milk_station] = milk_station.position
	home_positions[syrup_station] = syrup_station.position

	serve_button.pressed.connect(_on_serve_pressed)
	milk_bar.stopped.connect(_on_milk_poured)
	syrup_bar.stopped.connect(_on_syrup_poured)
	
	#temperature selection
	hot_button.pressed.connect(_on_temperature_chosen.bind("Hot"))
	iced_button.pressed.connect(_on_temperature_chosen.bind("Iced"))
	
	#syrup selection
	frostberry_button.pressed.connect(_on_syrup_chosen.bind("Frostberry"))
	amberglow_button.pressed.connect(_on_syrup_chosen.bind("Amberglow"))
	cinderspice_button.pressed.connect(_on_syrup_chosen.bind("Cinderspice"))
	bittersap_button.pressed.connect(_on_syrup_chosen.bind("Bittersap"))

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
	order_reminder.text = "Order: %s\nTemp: %s   Milk: %s   Syrup: %s" % [
		r.order_line, r.temperature, r.milk, r.syrup
	]


func update_cup() -> void:
	cup_label.text = "In the cup:\nTemp: %s   Milk: %s   Syrup: %s" % [
		display(selected_temperature), pour_status(selected_milk, milk_poured, milk_in_green), pour_status(selected_syrup, syrup_poured, syrup_in_green),
	]
	# Serve only appears once every station is done and there is an order.
	serve_button.visible = stage == Stage.READY and GameState.current_recipe != null


# Empties the cup and goes back to the first station.
func reset_cup() -> void:
	milk_bar.hide()
	syrup_bar.hide()
	selected_temperature = ""
	selected_milk = ""
	selected_syrup = ""
	milk_poured = false
	milk_in_green = false
	syrup_poured = false
	syrup_in_green = false
	milk_bar.reset()
	syrup_bar.reset()


	for button in milk_options.get_children():
		button.set_pressed_no_signal(false)
		button.show()

	for temp_card in temperature_options.get_children():
		var icon_button: TextureButton = temp_card.get_node("Icon")
		icon_button.set_pressed_no_signal(false)
		temp_card.show()

	for syrup_card in syrup_options.get_children():
		var icon_button: TextureButton = syrup_card.get_node("Icon")
		icon_button.set_pressed_no_signal(false)
		syrup_card.show()
	
	# Stop any slide in progress, put stations back home, hide milk and syrup.
	for station in [milk_station, syrup_station]:
		if slide_tweens.has(station):
			slide_tweens[station].kill()
		station.position = home_positions[station]
		station.hide()

	stage = Stage.TEMPERATURE
	update_cup()



func display(value: String) -> String:
	return "—" if value == "" else value.capitalize()

# Shows an ingredient plus how the pour went, e.g. "Moonmilk (perfect)".
func pour_status(choice: String, poured: bool, in_green: bool) -> String:
	if choice == "":
		return "—"
	if not poured:
		return "%s (click the bar!)" % choice.capitalize()
	return "%s (%s)" % [choice.capitalize(), "perfect" if in_green else "off"]

# --- Station animations ---

# Slides a station in from the right edge of the screen to its editor position.
func slide_in(station: Control) -> void:
	station.position = home_positions[station] + Vector2(slide_distance(), 0)
	station.show()
	animate_to(station, home_positions[station], false)


# Slides a station off the left edge of the screen, then hides it.
func slide_out(station: Control) -> void:
	animate_to(station, home_positions[station] - Vector2(slide_distance(), 0), true)


func animate_to(station: Control, target: Vector2, hide_when_done: bool) -> void:
	if slide_tweens.has(station):
		slide_tweens[station].kill()
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(station, "position", target, SLIDE_TIME)
	if hide_when_done:
		tween.tween_callback(station.hide)
	slide_tweens[station] = tween


func slide_distance() -> float:
	return get_viewport_rect().size.x


# --- Station 1: temperature ---

# Keeps the chosen cup on screen, hides the other one, and brings in the milk station.
func _on_temperature_chosen(value: String) -> void:
	if stage != Stage.TEMPERATURE:
		return
	selected_temperature = value
	for card in temperature_options.get_children():
		card.visible = card.name == (value + "Button")
	stage = Stage.MILK
	slide_in(milk_station)
	update_cup()


# --- Station 2: milk ---

# Choosing a milk (or switching to a different one) starts a new pour.
func _on_milk_chosen(value: String) -> void:
	if stage != Stage.MILK:
		return
	selected_milk = value
	milk_poured = false
	milk_in_green = false
	milk_bar.show() 
	milk_bar.start()
	update_cup()


# Called by the milk bar when the player clicks it. Moves on to the syrup station.
func _on_milk_poured(in_green: bool) -> void:
	milk_poured = true
	milk_in_green = in_green
	stage = Stage.SYRUP
	update_cup()
	await get_tree().create_timer(POUR_RESULT_DELAY).timeout
	# If Reset was pressed during the pause, don't slide anything.
	if not is_inside_tree() or stage != Stage.SYRUP or not milk_poured:
		return
	slide_out(milk_station)
	slide_in(syrup_station)
	update_cup()


# --- Station 3: syrup ---

# Picking a syrup finishes the drink: the Serve button appears.
func _on_syrup_chosen(value: String) -> void:
	if stage != Stage.SYRUP:
		return
	selected_syrup = value
	syrup_poured = false
	syrup_in_green = false
	#change bars
	milk_bar.hide()
	syrup_bar.show()
	syrup_bar.start()
	update_cup()


# Called by the syrup bar when the player clicks it. The drink is ready to serve.
func _on_syrup_poured(in_green: bool) -> void:
	syrup_poured = true
	syrup_in_green = in_green
	stage = Stage.READY
	update_cup()


# --- Station 4: serve ---

func _on_serve_pressed() -> void:
	GameState.record_result(calculate_quality())
	get_tree().change_scene_to_file("res://scenes/counter.tscn")


# --- Scoring ---

# Adds up the three parts. Possible totals: 100, 83, 67, 50, 33, 17 or 0.
func calculate_quality() -> float:
	var r: Recipe = GameState.current_recipe
	var quality := 0.0
	quality += part_points(selected_temperature, r.temperature, true)   # no amount for temperature
	quality += part_points(selected_milk, r.milk, milk_in_green)
	quality += part_points(selected_syrup, r.syrup, syrup_in_green)
	return roundf(quality)

# Wrong ingredient: 0. Right ingredient: full points in the green, half otherwise.
func part_points(chosen: String, wanted: String, in_green: bool) -> float:
	if not same(chosen, wanted):
		return 0.0
	if in_green:
		return POINTS_PER_PART
	return POINTS_PER_PART * MISSED_AMOUNT_MULTIPLIER

# Compares two values ignoring capitalization and spaces; empty counts as "none".
func same(a: String, b: String) -> bool:
	return normalize(a) == normalize(b)


func normalize(value: String) -> String:
	var v := value.strip_edges().to_lower()
	return "none" if v == "" else v
