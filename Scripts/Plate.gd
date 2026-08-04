class_name Plate
extends DropZone

var items: Array[Draggable] = []
var next_z := 1

func add(_item: Draggable) -> void:
	print("add 2 plate")
	items.erase(_item)
	items.append(_item)
	print("set z-index: %d " % [next_z])
	_item.z_index = next_z
	print(_item.z_index, " ", _item.item_name())
	next_z += 1
	log_items()

func remove(_item: Draggable) -> void:
	print("Item was removed")
	if items.has(_item):
		items.erase(_item)
		print("Setting z-index 0")
		_item.z_index = 0
		log_items()

func serve_and_clear() -> void:
	for item in items:
		if is_instance_valid(item):
			item.queue_free()
	items.clear()
	next_z = 1

func stack_names() -> Array:
	return items.map(func(i): return i.item_name())

func log_items() -> void:
	print("PLATE items (%d): %s" % [items.size(), str(stack_names())])
