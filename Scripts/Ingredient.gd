class_name Ingredient
extends Draggable

# The type of ingredient this is (e.g. patty, cheese, bun).
# Used to match items against what an order requires.
@export var ingredient_name: String = "item"

# Overrides Draggable.item_name() to report the ingredient's specific name.
func item_name() -> String:
	return ingredient_name
