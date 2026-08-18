class_name MouseUtil
extends RefCounted

# Checks if the object under the mouse is the top displayed object.
static func topmost_under_mouse(area: CollisionObject2D) -> bool:
	var point = area.get_global_mouse_position()
	var best: Draggable = null
	for hit in hits(area, point):
		var item := hit.collider as Draggable
		if item == null:
			continue
		if best == null or draws_above(item, best):
			best = item
	return best == area

# Decides between which if Draggable has a higher z_index than draggable b.
# Drops back to scene order if the z_index of draggable a and b are equal.
static func draws_above(a: Draggable, b: Draggable) -> bool:
	if a.z_index != b.z_index:
		return a.z_index > b.z_index
	return a.is_greater_than(b)

# Every object containing the point.
static func hits(area: CollisionObject2D, point: Vector2) -> Array[Dictionary]:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_areas = true
	params.collide_with_bodies = false
	return area.get_world_2d().direct_space_state.intersect_point(params)
