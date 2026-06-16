extends PanelContainer

## A custom checkbox UI component that pairs a label with a checkbox button.
##
## It manages toggling states, updates the label font color based on status, and
## exposes a signal for external listeners.

## Emitted when the checkbox is toggled.
signal toggled(toggled_on: bool)

## The label displaying the checkbox's name or text.
@onready var label: Label = $Label
## The button node handling the interactive toggled state.
@onready var check_button: TextureButton = $CenterContainer/CheckButton

func _ready() -> void:
	_update_visuals(check_button.button_pressed)

## Sets the checked state of the checkbox and updates its visuals.
## If the node is not yet ready, it awaits the ready signal first.
func set_checked(checked: bool) -> void:
	if is_node_ready():
		check_button.button_pressed = checked
		_update_visuals(checked)
	else:
		await ready
		check_button.button_pressed = checked
		_update_visuals(checked)

## Handles the internal toggled signal from the check button,
## updating visuals and emitting the toggled signal.
func _on_check_button_toggled(toggled_on: bool) -> void:
	_update_visuals(toggled_on)
	toggled.emit(toggled_on)

## Updates the font color of the label based on whether the checkbox is checked.
func _update_visuals(toggled_on: bool) -> void:
	if toggled_on:
		label.add_theme_color_override("font_color", Color("DFDFDF"))
	else:
		label.add_theme_color_override("font_color", Color("96827A"))
