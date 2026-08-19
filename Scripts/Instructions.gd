class_name Instructions
extends CanvasLayer

signal dismissed

@onready var start_button: Button = $Panel/Margin/Rules/Start

# 
func _ready() -> void:
	start_button.pressed.connect(dismiss)
	show_screen()

# 
func show_screen() -> void:
	visible = true
	get_tree().paused = true
	start_button.grab_focus()

# 
func dismiss() -> void:
	print("Dismissed")
	if not visible:
		return
	visible = false
	get_tree().paused = false
	dismissed.emit()

# 
func _unhandled_input(event: InputEvent) -> void:
	print("asdwe")
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		dismiss()
	elif event is InputEventMouseButton and event.pressed:
		dismiss()
