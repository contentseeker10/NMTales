@abstract class_name TestUI
extends CanvasLayer


func _unhandled_key_input(event: InputEvent) -> void:
	if self and is_instance_valid(self) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		TestManager.end_test()
