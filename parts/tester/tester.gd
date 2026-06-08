class_name Tester
extends Node2D

@export var test_type: String
@export var test_topic: String

var is_available: bool = false


func _on_interaction_area_body_entered(body: Player) -> void:
	body.can_attack = false
	is_available = true


func _on_interaction_area_body_exited(body: Player) -> void:
	body.can_attack = true
	is_available = false


func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_available and not TestManager.is_test_active:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.is_pressed():
				TestManager.start_test(test_type, test_topic)
