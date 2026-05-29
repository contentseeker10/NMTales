extends CanvasLayer

@onready var username_label: Label = $MarginContainer/VBoxContainer/UsernameLabel
@onready var level_label: Label = $MarginContainer/LevelProgression/LevelLabel
@onready var level_progress_bar: ProgressBar = $MarginContainer/LevelProgression/LevelProgressBar


func _ready() -> void:
	username_label.text = AuthManager.current_user_info.get("username", "Player")
	level_label.text = "lvl " + str(int(AuthManager.current_user_info.get("level")))
	level_progress_bar.max_value = (AuthManager.current_user_info.get("level") + 1) * 100.0
	level_progress_bar.value = AuthManager.current_user_info.get("xp", 0.0)
