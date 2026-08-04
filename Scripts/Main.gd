extends Node2D

const RECIPE := ["bottom_bun", "patty", "cheese", "sauce", "pickle", "top_bun"]

const ESSENTIALS := ["bottom_bun", "patty", "top_bun"]
const ESSENTIAL_LABELS := {
	"bottom_bun": "a bottom bun",
	"patty": "a patty",
	"top_bun": "a top bun",
}

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

var money := 0
var customer := 1
var order_start_ms := 0

func _ready() -> void:
	serve_button.pressed.connect(on_serve)
	order_start_ms = Time.get_ticks_msec()
	for item in get_tree().get_nodes_in_group("draggables"):
		register(item)
	update_money()
	start_order()

func register(item: Draggable) -> void:
	item.wasted.connect(on_item_wasted)
	item.spawned.connect(register)

func start_order() -> void:
	order_label.text = "CUSTOMER #%d\nCheeseburger:\nBottom Bun \nPatty \nCheese \nSauce \nPickle \nTop Bun"% customer
	order_start_ms = Time.get_ticks_msec()

func on_item_wasted(cost: int) -> void:
	money = max(0, money - cost)
	update_money()
	print("binned: -$%d" % cost)

func on_serve() -> void:
	print("Serving")
	if serve_button.pressed:
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

func update_money() -> void:
	money_label.text = "$%d" % money

func missing_essentials(stack: Array) -> Array:
	var missing := []
	for need in ESSENTIALS:
		if not stack.has(need):
			missing.append(need)
	return missing

func reject_serve(stack: Array, missing: Array) -> void:
	var wants := []
	for m in missing:

		wants.append(ESSENTIAL_LABELS[m])
	var hint := ""
	if stack.has("bun"):
		hint = "\n (click the bun to chop it)"
	result_label.text = "this burger is incomplete, it needs %s!%s" % [readable_list(wants), hint]
	print("REJECTED: missing %s (plate: %s)" % [str(missing), str(stack)])

func readable_list(bits: Array) -> String:
	if bits.size() <= 1:
		return "". join(bits)
	return ", ".join(bits.slice(0, bits.size() - 1)) + " and " + bits[-1]

func score_order(patties: Array, stack: Array, elapsed: float) -> int:
	var cook := 0.0
	for p in patties:
		cook +=(side_score(p.top_state) + side_score(p.bottom_state)) / 2.0
		if not patties.is_empty():
			cook /= patties.size()

	var n : int = min(stack.size(), RECIPE.size())
	var correct := 0
	for i in n:
		if stack[i] == RECIPE[i]:
			correct += 1
	var assembly := correct / float(RECIPE.size())
	
	var speed := 1.0
	if elapsed > TARGET_SECONDS:
		speed = max(0.0, 1.0 - (elapsed - TARGET_SECONDS) / TARGET_SECONDS)
	var speed_bonus : int = int(round(MAX_SPEED_BONUS * speed))
	
	var payout : int = int(round(BASE_PRICE * cook * assembly)) + speed_bonus
	
	print("--- SERVE --- cook=%.2f assembly=%.2f (%d/%d) time=%.1fs speed=%d => $%d" % [
		cook, assembly, correct, RECIPE.size(), elapsed, speed_bonus, payout])
	show_result(cook, assembly, correct, elapsed, speed_bonus, payout)
	return payout

func side_score(state: int) -> float:
	if state == CONGRATULATION:
		return 0.0
	var diff : int = abs(state - WELL)
	return max(0.0, 1.0 - diff * 0.3) # WELL=1.0  MED=0.7  RARE=0.4 RAW=0.1

func show_result(cook: float, _assembly: float, correct: int, elapsed: float, bonus: int, payout: int) -> void:
	result_label.text = "Payout: $%d\ncook %d%%  assembly %d/%d\ntime %.1fs speed +$%d" % [
		payout, int(round(cook * 100)), correct,RECIPE.size(), elapsed, bonus]
