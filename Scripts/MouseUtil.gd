class_name MouseUtil
extends RefCounted

# Checks whether the mouse is currently directly over the given collision area, 
# by doing a physics point-query at the mouse position and seeing if this area is one of the hits.
static func mouse_over(area: CollisionObject2D) -> bool:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = area.get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	var hits := area.get_world_2d().direct_space_state.intersect_point(params)
	for hit in hits:
		if hit.collider == area:
			return true
	return false
