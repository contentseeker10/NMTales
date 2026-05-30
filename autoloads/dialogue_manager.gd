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
	get_tree().paused = true
	_add_dialogue_scene(npc)
	_load_dialogue(npc.npc_id, 1)
	current_node_id = "start"
	advance_dialogue()

func _add_dialogue_scene(npc: NPC) -> void:
	dialogue = dialogue_scene.instantiate()
	dialogue.npc_name = npc.npc_id
	dialogue.npc_sprite_frames = npc.sprite.sprite_frames
	get_tree().current_scene.add_child(dialogue)

func _load_dialogue(npc_id: String, dialogue_id: int) -> void:
	var path: String = "res://assets/shared/dialogues/" + npc_id + "/" + str(dialogue_id) + ".json"
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		var content: String = file.get_as_text()
		file.close()
		current_dialogue_data = JSON.parse_string(content)
	else:
		push_error("Dialogue file was not found: " + path)
		current_dialogue_data = {}


func advance_dialogue() -> void:
	var node: Dictionary = current_dialogue_data.get(current_node_id, {})
	var answer: String = node.get("text", "error")
	dialogue.add_npc_answer(answer)
	var choices: Array = node.get("choices", [])
	dialogue.show_choices(choices)


func select_choice(choice_data: Dictionary) -> void:
	dialogue.add_player_answer(choice_data.get("text", "error"))
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
