## A pause menu overlay that manages the game's paused state and menu navigation.
##
## This menu can toggle pausing/unpausing of the scene tree, handle navigation to the
## achievements screen, and allow returning to the main menu.
extends CanvasLayer


## Listens for the "ui_cancel" action (typically Escape) to toggle pause menu visibility.
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

## Resumes the game by toggling the pause state when the continue button is clicked.
func _on_continue_button_pressed() -> void:
	_toggle_pause()


## Opens the achievements overlay by instantiating and adding it as a child.
func _on_achievements_button_pressed() -> void:
	var scene: PackedScene = preload("res://ui/menus/achievements/achievements.tscn")
	var ui = scene.instantiate()
	add_child(ui)


## Returns to the main menu scene and unpauses the game.
func _on_exit_button_pressed() -> void:
	_toggle_pause()
	get_tree().change_scene_to_file("res://ui/menus/main/main.tscn")
	
## Toggles the visibility of the pause menu and the pause state of the SceneTree,
## unless the current scene is the main menu.
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

