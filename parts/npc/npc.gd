@tool
## Represents a Non-Player Character (NPC) in the game world.
##
## This class manages the NPC's visual appearance (skin), quest availability,
## interaction areas, and triggering of dialogues or assistant interfaces.
class_name NPC
extends StaticBody2D

#region Node imports

## The label displaying the NPC's name or action prompt above their head.
@onready var action_icon: Label = $ActionIcon
## The animated sprite representing the NPC's visual representation.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

#endregion

#region Properties

## Unique identifier for the NPC.
@export var npc_id: String
## Display name of the NPC.
@export var npc_name: String
## Indicates if the NPC has a quest to offer.
@export var quest_giver: bool
## Indicates if the NPC acts as an educational assistant.
@export var assistant: bool
## The subject matter category of the assistant.
@export_enum("Math", "Language", "History") var assistant_type: String

#endregion

#region Private vars

## Tracks whether the player is currently close enough to interact with the NPC.
var _is_available: bool = false

#endregion


func _ready() -> void:
	action_icon.text = npc_name
	QuestManager.quest_updated.connect(func(_quest): update_quests_availability())
	QuestManager.quest_completed.connect(func(_quest): update_quests_availability())
	update_quests_availability()
	_update_skin()


#region Quest availability

## Updates the quest giver status based on whether there are available quests.
func update_quests_availability() -> void:
	quest_giver = _check_available_quests()

## Checks if there is any quest currently available to offer to the player.
## Returns true if a quest dialogue offer file exists and the quest is not completed or active.
func _check_available_quests() -> bool:
	if QuestManager.active_quest and QuestManager.active_quest.giver == npc_id:
		return false
	
	var quest_index: int = 1
	while quest_index < 10:
		var quest_id = "quest_" + str(quest_index)
		
		if QuestManager.is_quest_completed(npc_id, quest_id):
			quest_index += 1
			continue
		
		var dialogue_file_path = "res://assets/shared/dialogues/" + npc_id + "/quests/" + quest_id + "_offer.json"
		return FileAccess.file_exists(dialogue_file_path)
		
	return false

#endregion


#region Action label handler

## Handles showing the quest/name action label when the player enters the availability range.
func _on_quest_available_area_body_entered(_body: Node2D) -> void:
	if quest_giver:
		action_icon.global_position.y -= 10
		action_icon.text = npc_id + "\nМаю квест!"
	action_icon.show()


## Handles hiding the quest/name action label when the player leaves the availability range.
func _on_quest_available_area_body_exited(_body: Node2D) -> void:
	if quest_giver:
		action_icon.global_position.y += 10
	action_icon.hide()


## Updates the interaction state and changes action icon color when the player enters the interaction range.
func _on_interaction_area_body_entered(body: Node2D) -> void:
	action_icon.add_theme_color_override("font_color", Color.YELLOW)
	_is_available = true
	body.can_attack = false


## Resets the interaction state and icon color when the player leaves the interaction range.
func _on_interaction_area_body_exited(body: Node2D) -> void:
	action_icon.add_theme_color_override("font_color", Color.WHITE)
	_is_available = false
	body.can_attack = true

#endregion


#region Dialogue start

## Handles mouse inputs on the interaction area to initiate dialogue or open assistant interface.
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

## Supported skin types for the NPC.
enum NPCSkin { FemaleHumanBrown, MaleElfWhite, FemaleElfGreen, MaleDemonBlack, ElderBook }
## Mapping of skin types to their respective SpriteFrames resource paths.
const SKIN_TEXTURES := {
	NPCSkin.FemaleHumanBrown: preload("res://parts/npc/sprite_frames/1.tres"),
	NPCSkin.MaleElfWhite: preload("res://parts/npc/sprite_frames/2.tres"),
	NPCSkin.FemaleElfGreen: preload("res://parts/npc/sprite_frames/3.tres"),
	NPCSkin.MaleDemonBlack: preload("res://parts/npc/sprite_frames/4.tres"),
	NPCSkin.ElderBook: preload("res://parts/npc/sprite_frames/elder_book.tres")
}

## The visual skin selected for the NPC.
@export var skin: NPCSkin = NPCSkin.FemaleHumanBrown:
	set(value):
		skin = value
		_update_skin()

## Updates the sprite frames and plays the default idle animation based on the chosen skin.
func _update_skin() -> void:
	if not is_node_ready() and Engine.is_editor_hint():
		await ready
	if sprite and SKIN_TEXTURES.has(skin):
		sprite.sprite_frames = SKIN_TEXTURES[skin]
		sprite.play("idle_down")

#endregion
