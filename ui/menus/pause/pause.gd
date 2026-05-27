extends CanvasLayer


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _on_continue_button_pressed() -> void:
	_toggle_pause()
	

func _on_exit_button_pressed() -> void:
	_toggle_pause()
	get_tree().change_scene_to_file("res://ui/menus/main/main.tscn")
	
func _toggle_pause() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene is MainMenu:
		return
	get_tree().paused = !get_tree().paused
	self.visible = get_tree().paused
