class_name Draggable
extends Area2D

signal wasted(cost: int) 

const DRAG_Z := 100
const DRAG_THRESHOLD := 6.0

var home: Vector2
var pressed := false
var dragging := false
var press_mouse := Vector2.ZERO
var offset := Vector2.ZERO
var zone: DropZone = null
var plate: Plate = null

func _ready() -> void:
	home = global_position
	add_to_group("draggables")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	ready_extra()

func _on_area_entered(area: Area2D) -> void:
	if area is DropZone:
		zone = area

func _on_area_exited(area: Area2D) -> void:
	if area == zone:
		zone = null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and MouseUtil.mouse_over(self):
			pressed = true
			dragging = false
			press_mouse = get_global_mouse_position()
			get_viewport().set_input_as_handled()
		elif not event.pressed and pressed:
			if dragging:
				dragging = false
				print("Set z-index 0")
				z_index = 0
				_drop()
			else:
				on_clicked()
			pressed = false

func _physics_process(_delta: float) -> void:
	if pressed and not dragging:
		if get_global_mouse_position().distance_to(press_mouse) > DRAG_THRESHOLD:
			dragging = true
			z_index = DRAG_Z
			offset = global_position - get_global_mouse_position()
			on_drag_started()
	if dragging:
		global_position = get_global_mouse_position() + offset

func _drop() -> void:
	if zone:
		on_dropped_on_zone(zone)
	else:
		on_dropped_outside()

func return_home() -> void:
	global_position = home

func join_plate(_plate: Plate) -> void:
	print("join_plate")
	if plate != _plate:
		leave_plate()
		plate = _plate
	_plate.add(self)

func leave_plate() -> void: 
	if plate:
		plate.remove(self)
		plate = null

func bin() -> void:
	leave_plate()
	return_home()
	wasted.emit(waste_cost())

func on_dropped_on_zone(_dropped: DropZone) -> void: 
	match _dropped.type:
		DropZone.Type.PLATE:
			join_plate(_dropped as Plate)
		DropZone.Type.RUBBISH:
			print("binning")
			bin()
		_:
			leave_plate()
			return_home()

func waste_cost() -> int:
	return 1

func item_name() -> String:
	return name

func ready_extra() -> void: pass
func on_drag_started() -> void: pass
func on_clicked() -> void: pass
func on_dropped_outside() -> void: pass
