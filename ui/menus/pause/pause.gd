extends CanvasLayer


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _on_continue_button_pressed() -> void:
	_toggle_pause()


func _on_achievements_button_pressed() -> void:
	var scene: PackedScene = preload("res://ui/menus/achievements/achievements.tscn")
	var ui = scene.instantiate()
	add_child(ui)


func _on_exit_button_pressed() -> void:
	_toggle_pause()
	get_tree().change_scene_to_file("res://ui/menus/main/main.tscn")
	
func _toggle_pause() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene is MainMenu:
		return
	if not self.visible:
		get_tree().paused = true
		self.visible = true
	else:
		get_tree().paused = false
		self.visible = false
