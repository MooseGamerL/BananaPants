class_name DropZone
extends Area2D

# What type of zone this is, controls how Draggables react when dropped here.
enum Type { GRILL, PLATE, RUBBISH, COUNTER }

@export var type: Type = Type.GRILL

# This zone's collision shape as a rectangle in global coordinates.
func bounds() -> Rect2:
	var shape: CollisionShape2D = $CollisionShape2D
	return shape.get_global_transform() * (shape.shape as RectangleShape2D).get_rect()

# Finds a spot offset from a point inside the shaoe.
# If it is outside, the spot goes in the opposite direction.
func spot_beside(from: Vector2, offset: Vector2) -> Vector2:
	var rect := bounds()
	var spot: Vector2 = from + offset if rect.has_point(from + offset) else from - offset
	return spot.clamp(rect.position, rect.end)
