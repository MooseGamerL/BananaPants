extends DropZone

var stack: Array[String] = []

func on_item_dropped(item_name: String) -> void:
	stack.append(item_name)
	print("ASSEMBLY stack (%d): %s" % [stack.size(), str(stack)])
