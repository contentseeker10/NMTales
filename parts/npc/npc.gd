@tool
class_name NPC
extends StaticBody2D

#region Node imports

@onready var action_icon: Label = $ActionIcon
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

#endregion

#region Properties

@export var npc_id: String
@export var npc_name: String
@export var quest_giver: bool
@export var assistant: bool
@export_enum("Math", "Language", "History") var assistant_type: String

#endregion

#region Private vars

var _is_available: bool = false

#endregion


func _ready() -> void:
	action_icon.text = npc_name
	QuestManager.quest_updated.connect(func(_quest): update_quests_availability())
	QuestManager.quest_completed.connect(func(_quest): update_quests_availability())
	update_quests_availability()
	_update_skin()


#region Quest availability

func update_quests_availability() -> void:
	quest_giver = _check_available_quests()

func _check_available_quests() -> bool:
	if QuestManager.active_quest and QuestManager.active_quest.giver == npc_id:
		return false
	
	var quest_index: int = 1
	while true:
		var quest_id = "quest_" + str(quest_index)
		
		if QuestManager.is_quest_completed(npc_id, quest_id):
			quest_index += 1
			continue
		
		var dialogue_file_path = "res://assets/shared/dialogues/" + npc_id + "/quests/" + quest_id + "_offer.json"
		return FileAccess.file_exists(dialogue_file_path)
		
	return false

#endregion


#region Action label handler

func _on_quest_available_area_body_entered(_body: Node2D) -> void:
	if quest_giver:
		action_icon.global_position.y -= 10
		action_icon.text = npc_id + "\nМаю квест!"
	action_icon.show()


func _on_quest_available_area_body_exited(_body: Node2D) -> void:
	if quest_giver:
		action_icon.global_position.y += 10
	action_icon.hide()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	action_icon.add_theme_color_override("font_color", Color.YELLOW)
	_is_available = true
	body.can_attack = false


func _on_interaction_area_body_exited(body: Node2D) -> void:
	action_icon.add_theme_color_override("font_color", Color.WHITE)
	_is_available = false
	body.can_attack = true

#endregion


#region Dialogue start

func _on_interaction_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_available and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
		and event.is_pressed():
		
		if assistant:
			AssistantManager.start_chat(assistant_type, npc_name)
		else:
			DialogueManager.start_dialogue(self)
		
		get_viewport().set_input_as_handled()

#endregion


#region Skin changer

enum NPCSkin { FemaleHumanBrown, MaleElfWhite, FemaleElfGreen, MaleDemonBlack, ElderBook }
const SKIN_TEXTURES := {
	NPCSkin.FemaleHumanBrown: preload("res://parts/npc/sprite_frames/1.tres"),
	NPCSkin.MaleElfWhite: preload("res://parts/npc/sprite_frames/2.tres"),
	NPCSkin.FemaleElfGreen: preload("res://parts/npc/sprite_frames/3.tres"),
	NPCSkin.MaleDemonBlack: preload("res://parts/npc/sprite_frames/4.tres"),
	NPCSkin.ElderBook: preload("res://parts/npc/sprite_frames/elder_book.tres")
}

@export var skin: NPCSkin = NPCSkin.FemaleHumanBrown:
	set(value):
		skin = value
		_update_skin()

func _update_skin() -> void:
	if not is_node_ready() and Engine.is_editor_hint():
		await ready
	if sprite and SKIN_TEXTURES.has(skin):
		sprite.sprite_frames = SKIN_TEXTURES[skin]
		sprite.play("idle_down")

#endregion
