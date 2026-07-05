extends Area2D

#Cooking states and variables
enum CookState { RAW, RARE, MEDIUM, WELLDONE, CONGRATULATION }
enum Side { TOP, BOTTOM }
const STATE_NAMES := ["RAW", "RARE", "MEDIUM", "WELLDONE", "CONGRATULATION"]

var top_state: int = CookState.RAW
var bottom_state: int = CookState.RAW
var facing_down: int = Side.BOTTOM
var on_grill := false

#Drag variables
const DRAG_Z := 100
var home: Vector2
var dragging := false
var offset := Vector2.ZERO
var zone: DropZone = null

func _ready() -> void:
	home = global_position

func _on_area_entered(area: Area2D) -> void:
	if area is DropZone:
		zone = area

func _on_area_exited(area: Area2D) -> void:
	if area == zone:
		zone = null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and MouseUtil.mouse_over(self):
			dragging = true
			on_grill = false
			offset = global_position - get_global_mouse_position()
			z_index = DRAG_Z
			get_viewport().set_input_as_handled()
		elif not event.pressed and dragging:
			dragging = false
			z_index = 0
			_drop()

func _physics_process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() + offset

func _drop() -> void:
	if zone:
		match zone.type:
			DropZone.Type.GRILL:
				on_grill = true
				_print_state("on grill")
			DropZone.Type.RUBBISH:
				on_grill = false
				_print_state("rubbish")
			_:
				on_grill = false
				
func _print_state() -> void:
	pass
