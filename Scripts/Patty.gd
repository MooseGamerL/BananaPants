extends Draggable

#Cooking states and variables
enum CookState { RAW, RARE, MEDIUM, WELLDONE, CONGRATULATION }
const STATE_NAMES := ["RAW", "RARE", "MEDIUM", "WELLDONE", "CONGRATULATION"]
const STATE_COLOURS := [
	Color(0.90, 0.55, 0.55), #Raw
	Color(0.80, 0.42, 0.34), #Rare
	Color(0.60, 0.35, 0.24), #Medium
	Color(0.40, 0.10, 0.10), #Well Done
	Color(0.10, 0.10, 0.10), #Congratulation
]

var top_state: int = CookState.RAW
var bottom_state: int = CookState.RAW
var is_flipped = false
var on_grill := false

@onready var cook_timer: Timer = $CookTimer
@onready var visual: ColorRect = $Visual
@onready var state_sizzle: AudioStreamPlayer = $Sizzle #A sound to indicate patty state change

func ready_extra() -> void:
	cook_timer.timeout.connect(_on_cook_tick)
	update_visual()

func flip() -> void:
	is_flipped = not is_flipped
	_print_state("Flipped")
	update_visual()

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

func _down_state() -> int:
	return top_state if is_flipped else bottom_state

func _up_state() -> int:
	return bottom_state if is_flipped else top_state

func update_visual() -> void:
	visual.color = STATE_COLOURS[_up_state()]

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

func on_dropped_outside() -> void:
	on_grill = false
	_print_state("backto bin")

func on_drag_started() -> void: 
	on_grill = false

func on_clicked() -> void:
	if on_grill:
		flip()

func item_name() -> String:
	return "patty"

func waste_cost() -> int:
	return 3

func _print_state(tag: String) -> void:
	var down := "top" if is_flipped else "bottom"
	print ("[%s] top=%s bottom=%s (down=%s, on_grill=%s)" % [
		tag, STATE_NAMES[top_state], STATE_NAMES[bottom_state], down, on_grill])

func reset_cookstate() -> void:
	on_grill = false
	top_state = CookState.RAW
	bottom_state = CookState.RAW
	is_flipped = false
	update_visual()

func reset_to_bin() -> void:
	reset_cookstate()
	return_home()

func reset_extra() -> void:
	reset_cookstate()
