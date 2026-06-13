class_name Sign
extends Node2D

var _sign_ui_scene: PackedScene = preload("res://parts/sign/sign_ui.tscn")

@onready var _action_label: Label = $ActionLabel

var _is_available: bool = false

@export var title: String = "Title"
@export var content: String = "Content"


#region Action label handler

func _on_label_area_body_entered(body: Node2D) -> void:
	if body and body is Player:
		_action_label.show()


func _on_label_area_body_exited(body: Node2D) -> void:
	if body and body is Player:
		_action_label.hide()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body and body is Player:
		_action_label.add_theme_color_override("font_color", Color.YELLOW)
		body.can_attack = false
		_is_available = true


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body and body is Player:
		_action_label.add_theme_color_override("font_color", Color.WHITE)
		body.can_attack = true
		_is_available = false

#endregion


func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_available and event and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
		and event.is_pressed():
			var ui: SignUI = _sign_ui_scene.instantiate()
			get_tree().current_scene.add_child(ui)
			ui.title_label.text = title
			ui.content_text.text = content
