extends CanvasLayer

@onready var username_label: Label = $MarginContainer/VBoxContainer/UsernameLabel

@onready var current_objective_title: Label = $MarginContainer/VBoxContainer/BackgroundPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/CurrentObjectiveTitle
@onready var current_objective_description: Label = $MarginContainer/VBoxContainer/BackgroundPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/CurrentObjectiveDescription

@onready var level_label: Label = $MarginContainer/LevelProgression/LevelLabel
@onready var level_progress_bar: ProgressBar = $MarginContainer/LevelProgression/LevelProgressBar


func _ready() -> void:
	_load_user_data()
	QuestManager.quest_updated.connect(_on_quest_updated)
	QuestManager.quest_completed.connect(_on_quest_completed)

func _load_user_data() -> void:
	username_label.text = AuthManager.current_user_info.get("username", "Player")
	level_label.text = "lvl " + str(int(AuthManager.current_user_info.get("level")))
	level_progress_bar.max_value = (AuthManager.current_user_info.get("level") + 1) * 100.0
	level_progress_bar.value = AuthManager.current_user_info.get("xp", 0.0)


func _on_quest_updated(quest_data: Dictionary) -> void:
	current_objective_title.text = quest_data.get("title", "error")
	var objective: Dictionary = quest_data.get("objective", {})
	var current_amount: int = objective.get("current_amount", 0)
	var required_amount: int = objective.get("required_amount", 0)
	current_objective_description.text = quest_data.get("description", "error") \
									+ " (" + str(current_amount) + "/" + str(required_amount) + ")"


func _on_quest_completed(_quest_data: Dictionary) -> void:
	current_objective_title.text = "Пусто."
	current_objective_description.text = ""
