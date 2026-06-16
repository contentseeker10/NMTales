## A screen displayed when the player dies, offering options to revive or exit to the main menu.
class_name DeathScreen
extends CanvasLayer

## Button allowing the player to revive.
@onready var revive_button: Button = $CenterContainer/VBoxContainer/ReviveButton


## Handles the press event of the exit button.
## Resets the game's paused state, hides the death screen, and returns to the main menu.
func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	hide()
	get_tree().change_scene_to_file("res://ui/menus/main/main.tscn")

