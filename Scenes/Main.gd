extends Node2D

const RECIPE := ["bun", "patty", "cheese", "sauce", "pickle"]

const WELL := 3
const CONGRATULATION := 4
const BASE_PRICE := 10
const TARGET_SECONDS := 30.0
const MAX_SPEED_BONUS := 3

@onready var plate: Plate = $Plate/Plate
@onready var patty = $Patty
@onready var money_label: Label = $"Money Label"
@onready var serve_button: Button = $ServeButton
@onready var result_label: Label = $ResultLabel

var money := 0
var order_start_ms := 0

func _ready() -> void:
	print("ready")
	serve_button.pressed.connect(on_serve)
	order_start_ms = Time.get_ticks_msec()
	update_money()

func on_serve() -> void:
	print("nsdiurhiusehir")
	var stack := plate.stack_names()
	if stack.is_empty():
		print("no such thing a s a p l a te to s e r v e")
		return
	var elapsed := (Time.get_ticks_msec() - order_start_ms) / 1000.0
	var payout := score_order(patty.top_state, patty.bottom_state, stack, elapsed)
	money += payout
	update_money()

func update_money() -> void:
	money_label.text = "$%d" % money

func score_order(top_state: int, bottom_state: int, stack: Array, elapsed: float) -> int:
	var cook := (side_score(top_state) + side_score(bottom_state)) / 2.0
	
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
