class_name DropZone
extends Area2D

# What type of zone this is, controls how Draggables react when dropped here.
enum Type { GRILL, PLATE, RUBBISH, COUNTER }

@export var type: Type = Type.GRILL
