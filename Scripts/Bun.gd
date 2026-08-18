class_name Bun
extends Ingredient

# Colours used for each half of the chopped burger. Top colour is the same as the colour of unchopped bun
const BOTTOM_COLOUR := Color(0.943, 0.826, 0.633)
const TOP_COLOUR := Color(0.882, 0.576, 0.286)

const SPLIT_OFFSET := Vector2(45, 0)  # How far away the top half of the bun appears from bottom half

@onready var visual: ColorRect = $ColorRect

# Called when the player clicks on the bun.
# If the bun is whole, split it into two halves.
func on_clicked() -> void:
	if plate and ingredient_name == "bun":
		split()

# Splits a whole bun into a "bottom_bun" and a "top_bun" 
# Spawned copy slightly to the right, added to the same plate.
func split() -> void:
	var top := spawn_copy(plate.spot_beside(global_position, SPLIT_OFFSET)) as Bun
	ingredient_name = "bottom_bun"
	visual.color = BOTTOM_COLOUR
	top.become_top_bun()
	top.join_plate(plate)

# Turns this instance into the top half of a split bun, with name and colour.
func become_top_bun() -> void:
	ingredient_name = "top_bun"
	visual.color = TOP_COLOUR

# How much money is lost if either top or bottom bun are thrown away.
# Whole buns are worth more than an already split half.
func waste_cost() -> int:
	if ingredient_name == "bun":
		return 2
	return 1
