extends Draggable

# Cooking states and variables
enum CookState { RAW, RARE, MEDIUM, WELLDONE, CONGRATULATION }
const STATE_NAMES := ["RAW", "RARE", "MEDIUM", "WELLDONE", "CONGRATULATION"]
const STATE_COLOURS := [
	Color(0.90, 0.55, 0.55), # Raw
	Color(0.80, 0.42, 0.34), # Rare
	Color(0.60, 0.35, 0.24), # Medium
	Color(0.40, 0.10, 0.10), # Well Done
	Color(0.10, 0.10, 0.10), # Congratulation
]

var top_state: int = CookState.RAW     # Doneness of the side currently facing up.
var bottom_state: int = CookState.RAW  # Doneness of the side currently facing down.
var is_flipped = false                 # Whether the patty has been flipped over.
var on_grill := false                  # Whether the patty is currently on the grill (cooking).

@onready var cook_timer: Timer = $CookTimer
@onready var visual: ColorRect = $Visual
@onready var state_sizzle: AudioStreamPlayer = $Sizzle # A sound to indicate patty state change.

# Draggable hook: starts the cooktimer and sets the initial colour.
func ready_extra() -> void:
	cook_timer.timeout.connect(_on_cook_tick)
	cook_timer.start()
	update_visual()

# Flips the patty over, swapping which side faces up, and refreshes visuals.
func flip() -> void:
	is_flipped = not is_flipped
	_print_state("Flipped")
	update_visual()

# Called on cook timer each tick: while on grill, advances the doneness of whichever side is currently facing down,
# updates visual colour, and plays a sizzle sound whose pitch rises as the patty cooks further.
func _on_cook_tick() -> void:
	if not on_grill:
		return
	if is_flipped:
		top_state = min(top_state + 1, CookState.CONGRATULATION)
	else:
		bottom_state = min(bottom_state + 1, CookState.CONGRATULATION)
	_print_state("cooking larry")
	update_visual()
	state_sizzle.pitch_scale = 0.75 + _down_state() * 0.18
	state_sizzle.play()

# Returns the done state of whichever side is facing down.
func _down_state() -> int:
	return top_state if is_flipped else bottom_state

# Returns the up state of whichever side is facing up.
func _up_state() -> int:
	return bottom_state if is_flipped else top_state

# Sets the patty's colour to the doneness of the visible side.
func update_visual() -> void:
	visual.color = STATE_COLOURS[_up_state()]

# Overrides Draggable.on_dropped_on_zone: handle grill/plate specially,
# otherwise fall back to default Draggable behaviour.
func on_dropped_on_zone(dropped: DropZone) -> void: 
	match dropped.type:
		DropZone.Type.GRILL:
			on_grill = true
			leave_plate()
			_print_state("on grill")
		DropZone.Type.PLATE:
			print("patty drop on plate")
			join_plate(dropped)
			on_grill = false
		_:
			on_grill = false
			_print_state("Off grill")
			super.on_dropped_on_zone(dropped)

# Draggable hook: if dropped outside any zone, take the patty off the grill.
func on_dropped_outside() -> void:
	on_grill = false
	_print_state("backto bin")

# Draggable hook: picking a patty up always takes it off the grill.
func on_drag_started() -> void: 
	on_grill = false

# Draggable hook: clicking on a patty while it's on the grill flips it.
func on_clicked() -> void:
	if on_grill:
		flip()

# Overrides Draggable.item_name(): patties are always identified as "patty".
func item_name() -> String:
	return "patty"

# Overrides Draggable.waste_cost(): patties are the most expensive to waste.
func waste_cost() -> int:
	return 3

# Prints the current cook state of both sides.
func _print_state(tag: String) -> void:
	var down := "top" if is_flipped else "bottom"
	print ("[%s] top=%s bottom=%s (down=%s, on_grill=%s)" % [
		tag, STATE_NAMES[top_state], STATE_NAMES[bottom_state], down, on_grill])
