extends Node

var dialogue_scene: PackedScene = preload("res://ui/menus/dialogue/dialogue.tscn")
var dialogue: Dialogue

var current_dialogue_data: Dictionary = {}
var current_node_id: String = "start"


func _unhandled_key_input(event: InputEvent) -> void:
	if dialogue and is_instance_valid(dialogue) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		end_dialogue()


func start_dialogue(npc: NPC) -> void:
	EventBus.npc_talked.emit(npc.npc_id)
	get_tree().paused = true
	_add_dialogue_scene(npc)
	_load_dialogue(npc)
	current_node_id = "start"
	advance_dialogue()

func _add_dialogue_scene(npc: NPC) -> void:
	dialogue = dialogue_scene.instantiate()
	dialogue.npc = npc
	dialogue.npc_sprite_frames = npc.sprite.sprite_frames
	get_tree().current_scene.add_child(dialogue)

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

func _get_dialogue_id(npc: NPC) -> String:
	if QuestManager.active_quest and npc.npc_id == QuestManager.active_quest.giver:
		if QuestManager.active_quest.is_objective_done():
			return "quest_complete"
		else:
			return "quest_progress"
	else:
		var quest_index: int = 1
		while true:
			var quest_id = "quest_" + str(quest_index)
			if QuestManager.is_quest_completed(npc.npc_id, quest_id):
				quest_index += 1
				continue
			var quest_file_path = "res://assets/shared/dialogues/" \
								+ npc.npc_id + "/quests/" + quest_id + "_offer.json"
			if FileAccess.file_exists(quest_file_path):
				return npc.npc_id + "/quests/" + quest_id + "_offer"
			else:
				push_error("File not found: " + quest_file_path)
				break
		return npc.npc_id + "/casual"


func advance_dialogue() -> void:
	if not current_dialogue_data.has(current_node_id):
		push_error("Dialog node was not found: " + current_node_id)
		end_dialogue()
		return
	
	var node: Dictionary = current_dialogue_data.get(current_node_id, {})
	var answer: String = node.get("text", "error")
	dialogue.add_npc_answer(answer)
	var choices: Array = node.get("choices", [])
	dialogue.show_choices(choices)


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


func end_dialogue() -> void:
	current_dialogue_data = {}
	current_node_id = "start"
	if dialogue and is_instance_valid(dialogue):
		dialogue.queue_free()
		dialogue = null
	get_tree().paused = false
