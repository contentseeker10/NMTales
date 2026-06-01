class_name NPC
extends StaticBody2D

@onready var action_icon: Label = $ActionIcon
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var npc_id: String
var is_available: bool = false


func _on_quest_available_area_body_entered(_body: Node2D) -> void:
	action_icon.show()


func _on_quest_available_area_body_exited(_body: Node2D) -> void:
	action_icon.hide()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	action_icon.add_theme_color_override("font_color", Color.YELLOW)
	is_available = true
	body.can_attack = false


func _on_interaction_area_body_exited(body: Node2D) -> void:
	action_icon.add_theme_color_override("font_color", Color.WHITE)
	is_available = false
	body.can_attack = true


func _on_interaction_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_available and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
		and event.is_pressed():
		DialogueManager.start_dialogue(self)
		get_viewport().set_input_as_handled()
