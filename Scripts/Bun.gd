class_name Bun
extends Ingredient

const BOTTOM_COLOUR := Color(0.943, 0.826, 0.633)
const TOP_COLOUR := Color(0.882, 0.576, 0.286)

@onready var visual: ColorRect = $ColorRect

func on_clicked() -> void:
	if plate and ingredient_name == "bun":
		split()

func split() -> void:
	var top := spawn_copy(global_position + Vector2(45, 0)) as Bun
	ingredient_name = "bottom_bun"
	visual.color = BOTTOM_COLOUR
	top.become_top_bun()
	top.join_plate(plate)

func become_top_bun() -> void:
	ingredient_name = "top_bun"
	visual.color = TOP_COLOUR

func waste_cost() -> int:
	if ingredient_name == "bun":
		return 2
	return 1
