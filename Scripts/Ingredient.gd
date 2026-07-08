extends Draggable

@export var ingredient_name: String = "item"

func on_dropped_on_zone(dropped: DropZone) -> void:
	if dropped.type == DropZone.Type.ASSEMBLY:
		dropped.on_item_dropped(ingredient_name)
		print("placed %s on plate" % ingredient_name)
