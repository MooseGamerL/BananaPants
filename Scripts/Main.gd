extends Node2D

# The default (unmodified) count of each item required on a burger.
const BASE_ORDER := {
	"bottom_bun": 1, "patty": 1, "cheese": 1, "sauce": 1, "pickle": 1, "top_bun": 1
}

# Possible modifiers that can be applied to an order (e.g. "no pickles"),
# each overriding the count of one item.
const MODIFIERS := [
	{"name": "no pickles",    "item": "pickle", "count": 0},
	{"name": "extra pickles", "item": "pickle", "count": 2},
	{"name": "no sauce",      "item": "sauce",  "count": 0},
	{"name": "no cheese",     "item": "cheese", "count": 0},
	{"name": "double cheese", "item": "cheese", "count": 2},
	{"name": "double patty",  "item": "patty",  "count": 2}
]

# Order in which modifiable items are listed on the customer's ticket.
const TICKET_ORDER := ["patty", "cheese", "sauce", "pickle"]

# Score penalty (per side) if the bun isn't at the bottom/top of the stack.
const BUN_PLACEMENT_PENALTY := 0.15

# Items that must be present on the plate for an order to be servable at all.
const ESSENTIALS := ["bottom_bun", "patty", "top_bun"]
const ESSENTIAL_LABELS := {
	"bottom_bun": "a bottom bun",
	"patty": "a patty",
	"top_bun": "a top bun",
}

# Cook-state thresholds/tuning used when scoring patty doneness.
const WELL := 3
const CONGRATULATION := 4
const BASE_PRICE := 10
const TARGET_SECONDS := 30.0
const MAX_SPEED_BONUS := 3

@onready var plate: Plate = $Plate/Plate
@onready var serve_button: Button = $"Counter/Serve Button"
@onready var ding: AudioStreamPlayer = $"Counter/Serve Button/AudioStreamPlayer"
@onready var money_label: Label = $"Money Label"
@onready var result_label: Label = $"Result Label"
@onready var order_label: Label = $"Order Label"
@onready var instructions: Instructions = $Instructions

var money := 0
var customer := 1
var order_start_ms := 0
var order := BASE_ORDER.duplicate()

# Wire up the serve button, register any draggables already
# in the scene, refresh the UI, wait until instructions are dismissed to start.
func _ready() -> void:
	serve_button.pressed.connect(on_serve)
	instructions.dismissed.connect(start_order)
	for item in get_tree().get_nodes_in_group("draggables"):
		register(item)
	update_money()
	

# Hooks up an item's signals so Main is notified when it's wasted, and so
# any future copies spawned from it also get registered automatically.
func register(item: Draggable) -> void:
	item.wasted.connect(on_item_wasted)
	item.spawned.connect(register)

# Rolls a new random order, updates the ticket label, and resets the timer
# used for the speed bonus.
func start_order() -> void:
	order = roll_order()
	order_label.text = ticket_text()
	order_start_ms = Time.get_ticks_msec()
	print("ORDER #%d: %s" % [customer, str(order)])

# Builds a randomised order: starts from the base order, then applies 1-2
# random, non-conflicting modifiers (never two modifiers for the same item).
func roll_order() -> Dictionary:
	var _order := BASE_ORDER.duplicate()
	var pool := MODIFIERS.duplicate()
	pool.shuffle()
	var spoken_for := {}
	var wanted := 1 + (randi() % 2)
	for mod in pool:
		if spoken_for.size() >= wanted:
			break
		if spoken_for.has(mod.item):
			continue
		spoken_for[mod.item] = true
		_order[mod.item] = mod.count
	return _order

# Formats the current order into the multi-line text shown on the ticket.
func ticket_text() -> String:
	var lines := ["CUSTOMER #%d" % customer, "bun (click to chop)"]
	for item in TICKET_ORDER:
		var count: int = order.get(item, 0)
		if count == 0:
			lines.append("NO %s" % item)
		elif count == BASE_ORDER[item]:
			lines.append(item)
		else:
			lines.append("%s x%d" % [item, count])
	return "\n".join(lines)

# Called when any registered Draggable is thrown away: deducts its waste
# cost from the player's money (never going below zero).
func on_item_wasted(cost: int) -> void:
	money = max(0, money - cost)
	update_money()
	print("binned: -$%d" % cost)

# Called when the player presses the Serve button: validates the plate has
# the essential items, scores the order if valid, pays out, clears the
# plate, and starts the next order.
func on_serve() -> void:
	print("Serving")
	ding.play()
	var stack := plate.stack_names()
	var missing := missing_essentials(stack)
	if not missing.is_empty():
		reject_serve(stack, missing)
		return
	var elapsed := (Time.get_ticks_msec() - order_start_ms) / 1000.0
	var patties := []
	for item in plate.items:
		if item.item_name() == "patty":
			patties.append(item)
	var payout := score_order(patties, stack, elapsed)
	money += payout
	update_money()
	customer += 1
	plate.serve_and_clear()
	start_order()

# Refreshes the money label to match the current money value.
func update_money() -> void:
	money_label.text = "$%d" % money

# Returns which of the ESSENTIALS items are missing from the given stack.
func missing_essentials(stack: Array) -> Array:
	var missing := []
	for need in ESSENTIALS:
		if not stack.has(need):
			missing.append(need)
	return missing

# Shows a message telling the player what's missing when a serve attempt
# fails the essentials check (with a hint to chop the bun if needed).
func reject_serve(stack: Array, missing: Array) -> void:
	var wants := []
	for m in missing:
		wants.append(ESSENTIAL_LABELS[m])
	var hint := ""
	if stack.has("bun"):
		hint = "\n (click the bun to chop it)"
	result_label.text = "this burger is incomplete, \nit needs %s!%s" % [readable_list(wants), hint]
	print("REJECTED: missing %s (plate: %s)" % [str(missing), str(stack)])

# Joins a list of strings into a natural-language list, e.g.
# ["a", "b", "c"] -> "a, b and c".
func readable_list(bits: Array) -> String:
	if bits.size() <= 1:
		return "". join(bits)
	return ", ".join(bits.slice(0, bits.size() - 1)) + " and " + bits[-1]

# Calculates the payout for a served burger from patty doneness, how well
# the assembly matches the order, and how quickly it was served, then
# updates the result label. Returns the total payout.
func score_order(patties: Array, stack: Array, elapsed: float) -> int:
	var cook := 0.0
	for p in patties:
		cook += (side_score(p.top_state) + side_score(p.bottom_state)) / 2.0
		if not patties.is_empty():
			cook /= patties.size()

	var assembly := assembly_score(stack)
	
	var speed := 1.0
	if elapsed > TARGET_SECONDS:
		speed = max(0.0, 1.0 - (elapsed - TARGET_SECONDS) / TARGET_SECONDS)
	var speed_bonus : int = int(round(MAX_SPEED_BONUS * speed))
	
	var payout : int = int(round(BASE_PRICE * cook * assembly)) + speed_bonus
	
	print("<SERVE> cook=%.2f assembly=%.2f time=%.1fs speed=%d => $%d (wanted %s, got %s)" % [
		cook, assembly, elapsed, speed_bonus, payout, str(order), str(counts(stack))])
	show_result(cook, assembly, elapsed, speed_bonus, payout)
	return payout


# Scores how closely the plate's item counts match the order (0-1), then
# applies a penalty if the bottom/top buns aren't in the right place.
func assembly_score(stack: Array) -> float:
	var got := counts(stack)
	var wanted_total := 0
	for item in order:
		wanted_total += order[item]
	
	var every_item := {}
	for item in order:
		every_item[item] = true
	for item in got:
		every_item[item] = true
	
	var wrong = 0
	for item in every_item:
		wrong += abs(int(order.get(item, 0)) - int (got.get(item, 0)))
	var correctness: float = max (0.0, 1.0 - float(wrong) / float(wanted_total))
	
	var placement := 1.0
	if stack.is_empty() or stack[0] != "bottom_bun":
		placement -= BUN_PLACEMENT_PENALTY
	if stack.is_empty() or stack[-1] != "top_bun":
		placement -= BUN_PLACEMENT_PENALTY
	return correctness * placement

# Counts how many of each item name appear in the stack, e.g.
# ["patty", "patty", "cheese"] -> {"patty": 2, "cheese": 1}.
func counts(stack: Array) -> Dictionary:
	var _counts := {}
	for item_name in stack:
		_counts[item_name] = _counts.get(item_name, 0) + 1
	return _counts

# Converts a single side's cook state into a 0-1 score, peaking at WELL
# and dropping off the further away the state is (overcooked or undercooked).
func side_score(state: int) -> float:
	if state == CONGRATULATION:
		return 0.0
	var diff : int = abs(state - WELL)
	return max(0.0, 1.0 - diff * 0.3) # WELL=1.0  MED=0.7  RARE=0.4 RAW=0.1

# Updates the result label with a breakdown of the payout (cook %, order
# match %, time taken, and speed bonus).
func show_result(cook: float, _assembly: float, elapsed: float, bonus: int, payout: int) -> void:
	result_label.text = "Payout: $%d\ncook %d%% \norder %d%%\ntime %.1fs speed +$%d" % [
		payout, int(round(cook * 100)), int(round(_assembly * 100)), elapsed, bonus]
