class_name Tester
extends Node2D

@onready var _action_icon: Label = $ActionIcon

@export var test_type: String = "Type"
@export var test_topic: String = "Topic"

var is_available: bool = false


func _ready() -> void:
	_action_icon.text = test_topic


func _on_label_area_body_entered(body: Node2D) -> void:
	if body and body is Player:
		_action_icon.show()


func _on_label_area_body_exited(body: Node2D) -> void:
	if body and body is Player:
		_action_icon.hide()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body and body is Player:
		_action_icon.add_theme_color_override("font_color", Color.YELLOW)
		body.can_attack = false
		is_available = true


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body and body is Player:
		_action_icon.add_theme_color_override("font_color", Color.WHITE)
		body.can_attack = true
		is_available = false


func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_available and not TestManager.is_test_active:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.is_pressed():
				TestManager.start_test(test_type, test_topic)
