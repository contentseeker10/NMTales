extends StaticBody2D

@onready var action_icon: Label = $ActionIcon

@export var npc_id: String


func _on_quest_available_area_body_entered(body: Node2D) -> void:
	action_icon.show()


func _on_quest_available_area_body_exited(body: Node2D) -> void:
	action_icon.hide()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	action_icon.add_theme_color_override("font_color", Color.YELLOW)


func _on_interaction_area_body_exited(body: Node2D) -> void:
	action_icon.add_theme_color_override("font_color", Color.WHITE)


func _on_interaction_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var dialogue: CanvasLayer
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		dialogue = preload("res://ui/menus/dialogue/dialogue.tscn").instantiate()
	add_child(dialogue)
