class_name Draggable
extends Area2D

signal wasted(cost: int)         # Emitted when this item is thrown in the rubbish (carries its "waste cost").
signal spawned(item: Draggable)  # Emitted whenever a new copy of this item is spawned (e.g. from stock).

const DRAG_Z := 100          # z-index used while an item is being dragged, so it renders on top.
const DRAG_THRESHOLD := 6.0  # how far the mouse must move before a press counts as a drag.

var is_stock := true             # true if this is a "stock" item that restocks itself when picked up.
var home: Vector2                # the position this item returns/resets to.
var pressed := false             # true while the mouse button is held down on this item.
var dragging := false            # true once the press has turned into an actual drag.
var press_mouse := Vector2.ZERO  # mouse position at the moment the press started.
var offset := Vector2.ZERO       # offset between the item and the mouse while dragging.
var zone: DropZone = null        # the DropZone currently overlapping this item, if any.
var plate: Plate = null          # the plate this item currently belongs to, if any.

# Set up starting state, group membership, and area signals.
func _ready() -> void:
	home = global_position
	add_to_group("draggables")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	ready_extra()

# Tracks which DropZone this item is currently overlapping (entering).
func _on_area_entered(area: Area2D) -> void:
	if area is DropZone:
		zone = area

# Tracks which DropZone this item is currently overlapping (leaving).
func _on_area_exited(area: Area2D) -> void:
	if area == zone:
		zone = null

# Handles mouse-down/mouse-up on this item: starts a potential drag on press,
# and on release either finishes a drag (drop) or counts as a simple click.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and MouseUtil.topmost_under_mouse(self):
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

# Every physics frame: once the mouse has moved far enough while pressed,
# start dragging (and restock if this was a stock item); while dragging,
# follow the mouse.
func _physics_process(_delta: float) -> void:
	if pressed and not dragging:
		if get_global_mouse_position().distance_to(press_mouse) > DRAG_THRESHOLD:
			dragging = true	
			z_index = DRAG_Z
			offset = global_position - get_global_mouse_position()
			if is_stock:
				restock()
			on_drag_started()
	if dragging:
		global_position = get_global_mouse_position() + offset

# Called when the item is released after being dragged: hand off to whichever
# DropZone it's over, or treat it as dropped outside any zone.
func _drop() -> void:
	if zone:
		on_dropped_on_zone(zone)
	else:
		leave_plate()
		on_dropped_outside()

# Snaps the item back to its home position.
func return_home() -> void:
	global_position = home

# Called when a stock item starts being dragged away: this instance stops
# being "stock" and a fresh stock copy is spawned in its place at home.
func restock() -> void:
	is_stock = false
	var copy := spawn_copy(home)
	copy.become_stock(home)

# Duplicates this item as a brand-new node at the given position, adds it to
# the scene, and emits the `spawned` signal so listeners (e.g. Main) can hook
# up its signals.
func spawn_copy(where: Vector2) -> Draggable:
	var copy: Draggable = duplicate()
	get_parent().add_child(copy)
	copy.global_position = where
	copy.home = where
	copy.z_index = 0
	copy.is_stock = false
	spawned.emit(copy)
	return copy

# Marks this item as a stock item living at the given home position.
func become_stock(_home: Vector2) -> void:
	is_stock = true
	home = _home
	global_position = home

# Adds this item to a plate, first leaving any plate it was already on.
func join_plate(_plate: Plate) -> void:
	print("join_plate")
	if plate != _plate:
		leave_plate()
		plate = _plate
	_plate.add(self)

# Removes this item from its current plate, if it's on one.
func leave_plate() -> void: 
	print("left plate")
	if plate:
		plate.remove(self)
		plate = null

# Throws this item away: takes it off any plate, emits `wasted` with its
# waste cost, and destroys the node.
func bin() -> void:
	leave_plate()
	wasted.emit(waste_cost())
	queue_free()

# Called when the item is dropped on top of a DropZone. Default behaviour:
# join a plate if dropped on one, bin it if dropped on the rubbish, otherwise
# leave any plate and snap back home.
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

# Default money penalty for binning this item. Subclasses may override.
func waste_cost() -> int:
	return 1

# Default display/identifier name for this item. Subclasses may override.
func item_name() -> String:
	return name

# Hooks for subclasses to override.
func ready_extra() -> void: pass         # Extra setup on _ready()
func on_drag_started() -> void: pass     # Called right when a drag begins
func on_clicked() -> void: pass          # Called on a plain click (no drag)
func on_dropped_outside() -> void: pass  # Called when dropped outside any zone
