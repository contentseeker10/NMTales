class_name DeathScreen
extends CanvasLayer

@onready var revive_button: Button = $CenterContainer/VBoxContainer/ReviveButton


func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	hide()
	get_tree().change_scene_to_file("res://ui/menus/main/main.tscn")
