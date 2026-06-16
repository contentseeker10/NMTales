## Manages dialogue flow, NPC interaction, loading of dialogue JSON files, and selection of choices.
## This autoload script handles instantiating dialogue UI, loading JSON dialogue data,
## advancing conversation state, triggering quest/dialogue actions, and resuming gameplay.
extends Node

## The packed scene of the dialogue UI overlay.
var dialogue_scene: PackedScene = preload("res://ui/menus/dialogue/dialogue.tscn")
## The instantiated Dialogue controller node.
var dialogue: Dialogue

## Dictionary holding the loaded dialogue structure parsed from a JSON file.
var current_dialogue_data: Dictionary = {}
## The ID of the currently active dialogue node in the tree.
var current_node_id: String = "start"


## Closes the dialogue if the cancel action (ESC/UI cancel) is pressed.
func _unhandled_key_input(event: InputEvent) -> void:
	if dialogue and is_instance_valid(dialogue) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		end_dialogue()


## Starts a new dialogue sequence with the specified [NPC].
## Emits the npc_talked event, pauses the game, instantiates the UI, and loads dialogue files.
func start_dialogue(npc: NPC) -> void:
	EventBus.npc_talked.emit(npc.npc_id)
	get_tree().paused = true
	_add_dialogue_scene(npc)
	_load_dialogue(npc)
	current_node_id = "start"
	advance_dialogue()

## Instantiates the dialogue scene, configures its NPC context, and adds it to the current scene.
func _add_dialogue_scene(npc: NPC) -> void:
	dialogue = dialogue_scene.instantiate()
	dialogue.npc = npc
	dialogue.npc_sprite_frames = npc.sprite.sprite_frames
	get_tree().current_scene.add_child(dialogue)

## Loads dialogue JSON data from the shared assets directory matching the calculated dialogue ID.
func _load_dialogue(npc: NPC) -> void:
	var path: String = "res://assets/shared/dialogues/" + _get_dialogue_id(npc) + ".json"
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		var content: String = file.get_as_text()
		file.close()
		current_dialogue_data = JSON.parse_string(content)
	else:
		push_error("Dialogue file was not found: " + path)
		current_dialogue_data = {}

## Determines the correct dialogue JSON filename based on NPC identity, quest completion status, and active quest states.
func _get_dialogue_id(npc: NPC) -> String:
	var npc_id: String = npc.npc_id
	if npc_id == "npc_elder_book":
		npc_id = "npc_history_book"

	if npc_id == "npc_warning":
		if int(AuthManager.current_user_info.get("level", 0)) < 5:
			return "npc_warning/casual"
		elif QuestManager.is_quest_completed(npc_id, "quest_1"):
			return "npc_warning/casual_completed"
	elif npc_id == "npc_history_book":
		if QuestManager.is_quest_completed("npc_warning", "quest_1"):
			return "npc_history_book/casual"
		if QuestManager.active_quest and QuestManager.active_quest.id == "quest_hstr_1" and QuestManager.active_quest.is_objective_done():
			return "npc_history_book/casual"
		return "npc_history_book/quests/quest_1_offer"
		
	if QuestManager.active_quest:
		if npc_id == QuestManager.active_quest.giver:
			if QuestManager.active_quest.is_objective_done():
				return "quest_complete"
			else:
				return "quest_progress"
		else:
			var quest_index: int = 1
			var has_quest = false
			while quest_index < 10:
				var quest_id = "quest_" + str(quest_index)
				if QuestManager.is_quest_completed(npc_id, quest_id):
					quest_index += 1
					continue
				var quest_file_path = "res://assets/shared/dialogues/" \
									+ npc_id + "/quests/" + quest_id + "_offer.json"
				if FileAccess.file_exists(quest_file_path):
					has_quest = true
				break
			if has_quest:
				return "busy"
			else:
				return npc_id + "/casual"
	else:
		var quest_index: int = 1
		while quest_index < 10:
			var quest_id = "quest_" + str(quest_index)
			if QuestManager.is_quest_completed(npc_id, quest_id):
				quest_index += 1
				continue
			var quest_file_path = "res://assets/shared/dialogues/" \
								+ npc_id + "/quests/" + quest_id + "_offer.json"
			if FileAccess.file_exists(quest_file_path):
				return npc_id + "/quests/" + quest_id + "_offer"
			else:
				push_error("File not found: " + quest_file_path)
				break
		return npc_id + "/casual"


## Advances the conversation to the current dialogue node, displaying NPC speech and choice options.
func advance_dialogue() -> void:
	if not current_dialogue_data.has(current_node_id):
		push_error("Dialog node was not found: " + current_node_id)
		end_dialogue()
		return
	
	var node: Dictionary = current_dialogue_data.get(current_node_id, {})
	var answer: String = node.get("text", "error")
	dialogue.add_npc_answer(answer)
	AudioManager.play_sfx(preload("res://assets/shared/audio/ui/npc_responded.wav"), 0.05, "SFX")
	var choices: Array = node.get("choices", [])
	dialogue.show_choices(choices)


## Handles the player selecting a dialogue choice. Emits triggers if the choice has an associated action,
## and either advances dialogue to the next node or ends it.
func select_choice(choice_data: Dictionary) -> void:
	dialogue.add_player_answer(choice_data.get("text", "error"))
	
	var action: Dictionary = choice_data.get("action", {})
	if not action.is_empty():
		EventBus.dialogue_action_triggered.emit(dialogue.npc, action)
	
	var next_node: String = choice_data.get("next_node", "exit")
	if next_node == "exit":
		end_dialogue()
	else:
		current_node_id = next_node
		dialogue.clear_choices_ui()
		advance_dialogue()


## Closes the active dialogue, cleans up the dialogue UI instance, resets state variables, and unpauses the game tree.
func end_dialogue() -> void:
	current_dialogue_data = {}
	current_node_id = "start"
	if dialogue and is_instance_valid(dialogue):
		dialogue.queue_free()
		dialogue = null
	get_tree().paused = false
