class_name DropZone
extends Area2D

enum Type { GRILL, ASSEMBLY, RUBBISH, COUNTER }

@export var type: Type = Type.GRILL

func snap_position() -> Vector2:
	var marker := get_node_or_null("SnapPoint") as Node2D
	return marker.global_position if marker else global_position

func on_item_dropped(item_name: String) -> void:
	print("on_item_dropped %s" % [item_name])
	pass
