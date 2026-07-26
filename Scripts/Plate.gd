class_name Plate
extends DropZone

var items: Array[Draggable] = []
var next_z := 1

func add(_item: Draggable) -> void:
	print("add 2 plate")
	if not items.has(_item):
		items.append(_item)
	print("set z-index: %d " % [next_z])
	_item.z_index = next_z
	print(_item.z_index, " ", _item.item_name())
	next_z += 1
	log_items()

func remove(_item: Draggable) -> void:
	if items.has(_item):
		items.erase(_item)
		print("Setting z-index 0")
		_item.z_index = 0
		log_items()

func new_round() -> void:
	items.clear()
	next_z = 1

func stack_names() -> Array:
	return items.map(func(i): return i.item_name())

func log_items() -> void:
	print("PLATE items (%d): %s" % [items.size(), str(stack_names())])
