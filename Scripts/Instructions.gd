class_name Instructions
extends CanvasLayer

signal dismissed

@onready var start_button: Button = $Panel/Margin/Rules/Start

# On start connects the button to dissmiss function and shows the screen.
func _ready() -> void:
	start_button.pressed.connect(dismiss)
	show_screen()

# Makes the screen visible and pauses the game while the screen is up.
func show_screen() -> void:
	visible = true
	get_tree().paused = true
	start_button.grab_focus()

# Hides the start screen and unpauses the game.
func dismiss() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	dismissed.emit()

# Calls dismiss whenever the button is pressed.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		dismiss()
	elif event is InputEventMouseButton and event.pressed:
		dismiss()
