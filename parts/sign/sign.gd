## A sign node that displays an action prompt when the player is close,
## and allows opening a UI dialog containing text content when clicked.
class_name Sign
extends Node2D

var _sign_ui_scene: PackedScene = preload("res://parts/sign/sign_ui.tscn")

@onready var _action_label: Label = $ActionLabel

var _is_available: bool = false

## The title displayed in the sign UI when opened.
@export var title: String = "Title"
## The main text content displayed in the sign UI when opened.
@export var content: String = "Content"


#region Action label handler

## Called when a physics body enters the label detection area. Shows the action prompt label if the body is the Player.
func _on_label_area_body_entered(body: Node2D) -> void:
	if body and body is Player:
		_action_label.show()


## Called when a physics body exits the label detection area. Hides the action prompt label if the body is the Player.
func _on_label_area_body_exited(body: Node2D) -> void:
	if body and body is Player:
		_action_label.hide()


## Called when a physics body enters the interaction area. Highlights the action prompt,
## prevents the Player from attacking while interacting, and marks the sign as available for reading.
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body and body is Player:
		_action_label.add_theme_color_override("font_color", Color.YELLOW)
		body.can_attack = false
		_is_available = true


## Called when a physics body exits the interaction area. Resets the action prompt style,
## restores Player attacking capability, and marks the sign as unavailable.
func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body and body is Player:
		_action_label.add_theme_color_override("font_color", Color.WHITE)
		body.can_attack = true
		_is_available = false

#endregion


## Handles input events on the sign's click collision area. If the sign is available
## and left-clicked, instantiates the sign UI and sets its title and content.
func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_available and event and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
		and event.is_pressed():
			var ui: SignUI = _sign_ui_scene.instantiate()
			get_tree().current_scene.add_child(ui)
			ui.title_label.text = title
			ui.content_text.text = content

