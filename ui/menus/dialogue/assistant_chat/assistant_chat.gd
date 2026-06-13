class_name AssistantChat
extends CanvasLayer

#region Private vars

var _player_text_scene: PackedScene = preload("res://ui/menus/dialogue/answers/player_text.tscn")
var _npc_text_scene: PackedScene = preload("res://ui/menus/dialogue/answers/npc_text.tscn")

var _last_prompt: RichTextLabel
var _last_answer: RichTextLabel

#endregion

#region Node imports

@onready var assistant_name_label: Label = $VBoxContainer/AssistantNameLabel
@onready var line_edit: LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var chat_box: VBoxContainer = $VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/ChatBox

#endregion


#region Chatting handler

func _on_send_button_pressed() -> void:
	var prompt := line_edit.text
	line_edit.clear()
	
	_add_prompt(prompt)
	_add_answer()
	
	var response := await AssistantManager.send_player_prompt(prompt)
	
	if response.is_empty():
		_last_answer.queue_free()
		_last_prompt.text = "Помилка відправлення запиту"
		line_edit.text = prompt
		return
	
	_load_answer(response)


func _add_prompt(prompt: String) -> void:
	var player_prompt: RichTextLabel = _player_text_scene.instantiate()
	player_prompt.text = "[b]" + AuthManager.current_user_info.get("username", "error") + ":[/b]\n" \
					+ prompt
	chat_box.add_child(player_prompt)
	_last_prompt = player_prompt


func _add_answer() -> void:
	var assistant_answer: RichTextLabel = _npc_text_scene.instantiate()
	assistant_answer.text = "[b]Асистент:[/b]\n" + \
							"[shake rate=20.0 level=5 connected=1]...[/shake]"
	chat_box.add_child(assistant_answer)
	_last_answer = assistant_answer

func _load_answer(data: Dictionary) -> void:
	_last_answer.text = "[b]Асистент:[/b]\n"
	# TODO: Loading LLM response (ensure API correctness)
	_last_answer.text += data.get("answer", "error")

#endregion


func _on_exit_button_pressed() -> void:
	AssistantManager.end_chat()
	queue_free()
