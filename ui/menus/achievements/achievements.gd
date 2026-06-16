## UI container representing the Achievements menu.
## Displays the player's achievements inside a grid by dynamically fetching
## and instantiating achievement components.
class_name AchievementsUI
extends CanvasLayer


## Initializes the Achievements UI. Sets the process mode to always process,
## connects input handlers for background/exit button clicks, clears design-time placeholders,
## and fetches and instantiates achievement list items.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Close on background click
	$ColorRect.gui_input.connect(_on_color_rect_gui_input)
	
	# Close on Exit Button click
	$ExitButton.pressed.connect(_close_menu)
	
	# Clear default plate elements
	var grid: GridContainer = $VBoxContainer/PanelContainer/ScrollContainer/MarginContainer/GridContainer
	for child in grid.get_children():
		child.queue_free()
		
	# Populate dynamically
	var achievements: Array = await AchievementsManager.fetch_achievements()
	var plate_scene: PackedScene = preload("res://ui/components/achievement_plate/achivement_plate.tscn")
	
	for ach in achievements:
		var code: String = ach.get("code", "")
		var title: String = AchievementsManager.get_translated_title(code, ach.get("title", ""))
		var desc: String = AchievementsManager.get_translated_description(code, ach.get("description", ""))
		var current_progress: int = int(ach.get("currentProgress", 0))
		var target_progress: int = int(ach.get("targetProgress", 0))
		
		var plate = plate_scene.instantiate()
		grid.add_child(plate)
		plate.title_label.text = title
		plate.description_label.text = desc + " (" + str(current_progress) + "/" + str(target_progress) + ")"
		plate.unlocked = ach.get("isUnlocked", false)


## Callback triggered by GUI input on the background overlay ColorRect.
## Closes the achievements menu if a left click is detected.
func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_menu()


## Callback triggered by unhandled key input. Closes the menu if the
## cancel action (e.g. Escape key) is pressed.
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close_menu()
		get_viewport().set_input_as_handled()


## Closes and frees the achievements menu interface.
func _close_menu() -> void:
	queue_free()

