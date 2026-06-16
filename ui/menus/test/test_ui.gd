## Abstract base class for test user interfaces.
## 
## Provides common functionality for test UIs, such as handling input 
## to end the current test session when the cancel action is pressed.
@abstract class_name TestUI
extends CanvasLayer


## Handles unhandled key input events.
## If the "ui_cancel" action is pressed, handles the event and tells
## TestManager to end the active test.
func _unhandled_key_input(event: InputEvent) -> void:
	if self and is_instance_valid(self) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		TestManager.end_test()

