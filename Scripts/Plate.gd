class_name Plate
extends DropZone

var items: Array[Draggable] = []  # Items currently stacked on the plate, in stacking order.
var next_z := 1                   # next z-index to assign so newer stacked items render above older ones.

# Adds an item to the plate: moves it to the top of the stack, and gives it the next z-index so it renders on top.
func add(_item: Draggable) -> void:
	print("add 2 plate")
	items.erase(_item)
	items.append(_item)
	print("set z-index: %d " % [next_z])
	_item.z_index = next_z
	print(_item.z_index, " ", _item.item_name())
	next_z += 1
	log_items()

# Removes an item from a stack and resets its z-index.
func remove(_item: Draggable) -> void:
	print("Item was removed")
	if items.has(_item):
		items.erase(_item)
		print("Setting z-index 0")
		_item.z_index = 0
		log_items()

# Serves the burger, destroys every item currently on the plate and resets the stack and z-index counter for the next order
func serve_and_clear() -> void:
	for item in items:
		if is_instance_valid(item):
			item.queue_free()
	items.clear()
	next_z = 1

# Returns the item names of everything on the plate, bottom to top.
func stack_names() -> Array:
	return items.map(func(i): return i.item_name())

# Prints the current contents of the plate.
func log_items() -> void:
	print("PLATE items (%d): %s" % [items.size(), str(stack_names())])
