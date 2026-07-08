class_name DropZone
extends Area2D

enum Type { GRILL, PLATE, RUBBISH, COUNTER }

@export var type: Type = Type.GRILL

func snap_position() -> Vector2:
	var marker := get_node_or_null("SnapPoint") as Node2D
	return marker.global_position if marker else global_position
