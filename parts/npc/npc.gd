class_name NPC
extends StaticBody2D

@onready var action_icon: Label = $ActionIcon
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var npc_id: String
var is_available: bool = false

var quests: Array[Quest] = []


func _ready() -> void:
	_load_quests()


func _load_quests() -> void:
	var path: String = "res://assets/shared/quests/" + npc_id
	for i in range(_get_quest_count(path)):
		var quest: Quest = Quest.new(npc_id, "quest_" + str(i + 1))
		quests.append(quest)

func _get_quest_count(path: String) -> int:
	var count = 0
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				count += 1
			file_name = dir.get_next()
	else:
		push_error("Unable to open: ", path)
		return -1
	return count


func _on_quest_available_area_body_entered(_body: Node2D) -> void:
	action_icon.show()


func _on_quest_available_area_body_exited(_body: Node2D) -> void:
	action_icon.hide()


func _on_interaction_area_body_entered(_body: Node2D) -> void:
	action_icon.add_theme_color_override("font_color", Color.YELLOW)
	is_available = true


func _on_interaction_area_body_exited(_body: Node2D) -> void:
	action_icon.add_theme_color_override("font_color", Color.WHITE)
	is_available = false


func _on_interaction_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_available and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
		and event.is_pressed():
		DialogueManager.start_dialogue(self)
