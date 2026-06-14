class_name AchievementsUI
extends CanvasLayer


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


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_menu()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close_menu()
		get_viewport().set_input_as_handled()


func _close_menu() -> void:
	queue_free()
