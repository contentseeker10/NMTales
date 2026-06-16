## Heads-Up Display (HUD) controller that manages UI elements visible to the player during gameplay.
##
## This class displays user information, quest objectives, level progression, and handles
## notebook toggle/key inputs as well as the death screen when the player dies.
class_name HUD
extends CanvasLayer

#region Node imports

@onready var username_label: Label = $MarginContainer/VBoxContainer/UsernameLabel
@onready var current_objective_title: Label = $MarginContainer/VBoxContainer/BackgroundPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/CurrentObjectiveTitle
@onready var current_objective_description: Label = $MarginContainer/VBoxContainer/BackgroundPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/CurrentObjectiveDescription
@onready var level_label: Label = $MarginContainer/LevelProgression/LevelLabel
@onready var level_progress_bar: ProgressBar = $MarginContainer/LevelProgression/LevelProgressBar
@onready var notebook: NotebookScreen = $Notebook
@onready var death_screen: DeathScreen = $DeathScreen

#endregion


## Called when the node enters the scene tree.
## Connects signals from managers and initializes user and quest UI elements.
func _ready() -> void:
	_load_user_data()
	
	QuestManager.quest_updated.connect(_on_quest_updated)
	QuestManager.objective_completed.connect(_on_objective_completed)
	QuestManager.quest_completed.connect(_on_quest_completed)
	
	TestManager.session_finished.connect(_on_session_finished)
	
	if QuestManager.active_quest:
		_on_quest_updated(QuestManager.active_quest)
	
	EventBus.player_died.connect(_on_player_died)

## Loads the current user's name and triggers level progression UI update.
func _load_user_data() -> void:
	username_label.text = AuthManager.current_user_info.get("username", "Player")
	_update_level_progression()


#region Quest info update

## Updates the current objective title and details when a quest has changed.
func _on_quest_updated(quest: Quest) -> void:
	current_objective_title.text = quest.title
	current_objective_description.text = quest.description \
									+ " (" + str(quest.current_amount) \
									+ "/" + str(quest.required_amount) + ")"


## Updates the UI text to guide the player back to the quest giver when objective is completed.
func _on_objective_completed(quest: Quest) -> void:
	current_objective_description.text = "Завдання виконано.\nПоговоріть з " + quest.giver


## Clears active quest UI and updates level/experience when a quest is fully completed.
func _on_quest_completed(_quest: Quest) -> void:
	current_objective_title.text = "Пусто."
	current_objective_description.text = ""
	_update_level_progression()

#endregion


#region Level/Experience update

## Updates level progression if the session completes successfully.
func _on_session_finished(success: bool) -> void:
	if success:
		_update_level_progression()


## Fetches updated user information and updates level/XP progression bar values.
func _update_level_progression() -> void:
	await AuthManager.update_user_info()
	level_label.text = "lvl " + str(int(AuthManager.current_user_info.get("level", 0)))
	level_progress_bar.max_value = (AuthManager.current_user_info.get("level") + 1) * 100.0
	level_progress_bar.value = AuthManager.current_user_info.get("xp", 0.0)

#endregion


#region Notebook handler

## Pauses the game and shows the Notebook screen when the notebook button is pressed.
func _on_notebook_button_pressed() -> void:
	get_tree().paused = true
	notebook.show()

## Processes unhandled input events to close the notebook and resume the game upon pressing cancel.
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		notebook.hide()
		get_tree().paused = false

#endregion


## Displays the death screen when the player dies.
func _on_player_died() -> void:
	death_screen.show()

