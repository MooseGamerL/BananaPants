extends Ingredient

const BOTTOM_COLOUR := Color(0.943, 0.826, 0.633)
const TOP_COLOUR := Color(0.882, 0.576, 0.286)

var is_spawned := false
var original_name: String
var original_colour: Color

@onready var visual: ColorRect = $ColorRect

func ready_extra() -> void:
	original_name = ingredient_name
	original_colour = visual.color

func on_clicked() -> void:
	if plate and ingredient_name == "bun":
		split()

func split() -> void:
	var top := duplicate()
	ingredient_name = "bottom_bun"
	visual.color = BOTTOM_COLOUR
	top.position = global_position + Vector2(20, -23)
	get_parent().add_child(top)
	top.become_top_bun()
	top.join_plate(plate)

func become_top_bun() -> void:
	ingredient_name = "top_bun"
	is_spawned = true
	z_index = 0
	visual.color = TOP_COLOUR

func reset() -> void:
	if is_spawned:
		leave_plate()
		queue_free()
	else:
		super.reset()
		ingredient_name = original_name
		visual.color = original_colour
