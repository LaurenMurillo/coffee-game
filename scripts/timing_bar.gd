class_name TimingBar
extends Control
## A timing bar like Papa's Freezeria: a marker slides back and forth,
## and the player clicks the bar to stop it. Stopping inside the green
## zone means the right amount was dispensed.
##
## How other scripts use it:
##   bar.start()                       starts the marker moving
##   bar.reset()                       stops it and puts it back at the start
##   bar.stopped.connect(my_function)  my_function(in_green: bool) runs when the player clicks

signal stopped(in_green: bool)

# --- Tuning (change these in the Inspector for each bar) ---
@export var speed: float = 0.8              # how many bar-lengths the marker moves per second
@export var green_width: float = 0.2        # how much of the bar is green (0.2 = 20%)
@export var randomize_green: bool = true    # move the green zone to a new spot each time
@export var bar_color: Color = Color(0.25, 0.25, 0.25)
@export var green_color: Color = Color(0.3, 0.8, 0.3)
@export var marker_color: Color = Color(1, 1, 1)

# --- State ---
var marker: float = 0.0          # marker position: 0.0 = left edge, 1.0 = right edge
var direction: float = 1.0       # 1 = moving right, -1 = moving left
var running: bool = false
var green_start: float = 0.4     # where the green zone begins (0.0 to 1.0)


func _ready() -> void:
	# Give the bar a visible size if none was set in the Inspector.
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(300, 16)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)


# Starts the marker moving from the left edge.
func start() -> void:
	if randomize_green:
		green_start = randf_range(0.0, 1.0 - green_width)
	marker = 0.0
	direction = 1.0
	running = true
	set_process(true)
	queue_redraw()


# Stops the marker and returns it to the left edge without reporting a result.
func reset() -> void:
	running = false
	set_process(false)
	marker = 0.0
	queue_redraw()


func is_in_green() -> bool:
	return marker >= green_start and marker <= green_start + green_width


# Moves the marker every frame, bouncing off both ends.
func _process(delta: float) -> void:
	marker += direction * speed * delta
	if marker >= 1.0:
		marker = 1.0
		direction = -1.0
	elif marker <= 0.0:
		marker = 0.0
		direction = 1.0
	queue_redraw()


# A left click on the bar stops the marker and reports whether it landed in the green.
func _gui_input(event: InputEvent) -> void:
	if not running:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		running = false
		set_process(false)
		queue_redraw()
		stopped.emit(is_in_green())
		accept_event()


# Draws the bar: background, green zone, then the marker on top.
func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), bar_color)
	draw_rect(Rect2(green_start * w, 0, green_width * w, h), green_color)
	var x := marker * w
	draw_rect(Rect2(x - 2, -4, 4, h + 8), marker_color)
