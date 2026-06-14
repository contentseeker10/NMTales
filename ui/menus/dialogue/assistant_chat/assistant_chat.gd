class_name AssistantChat
extends CanvasLayer

#region Private vars

var _player_text_scene: PackedScene = preload("res://ui/menus/dialogue/answers/player_text.tscn")
var _npc_text_scene: PackedScene = preload("res://ui/menus/dialogue/answers/npc_text.tscn")

var _last_prompt: RichTextLabel
var _last_answer: RichTextLabel

var _is_waiting: bool = false

#endregion

#region Node imports

@onready var assistant_name_label: Label = $VBoxContainer/AssistantNameLabel
@onready var scroll_container: ScrollContainer = $VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer
@onready var greeting_text: RichTextLabel = $VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/ChatBox/GreetingText
@onready var line_edit: LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var chat_box: VBoxContainer = $VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/ChatBox
@onready var send_button: Button = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/SendButton

#endregion


func _ready() -> void:
	line_edit.text_submitted.connect(_on_line_edit_text_submitted)


func load_history(messages: Array) -> void:
	for message: Dictionary in messages:
		if message.get("role", "") == "user":
			_add_prompt(message.get("content", ""))
		else:
			_append_assistant_text(message.get("content", ""))
	await _scroll_to_bottom()


#region Chatting handler

func _on_line_edit_text_submitted(_new_text: String) -> void:
	_on_send_button_pressed()


func _on_send_button_pressed() -> void:
	if _is_waiting:
		return

	var prompt := line_edit.text.strip_edges()
	if prompt.is_empty():
		return

	line_edit.clear()
	_set_input_enabled(false)

	_add_prompt(prompt)
	_add_answer()
	await _scroll_to_bottom()

	var response := await AssistantManager.send_player_prompt(prompt)

	if response.has("answer"):
		_load_answer(response)
	else:
		_show_error(response.get("error", "Не вдалося отримати відповідь."))
		line_edit.text = prompt
	
	await _scroll_to_bottom()
	_set_input_enabled(true)


func _set_input_enabled(enabled: bool) -> void:
	_is_waiting = not enabled
	line_edit.editable = enabled
	send_button.disabled = not enabled
	if enabled:
		line_edit.grab_focus()


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
	_last_answer.text = "[b]Асистент:[/b]\n" + data.get("answer", "error")


func _append_assistant_text(content: String) -> void:
	var bubble: RichTextLabel = _npc_text_scene.instantiate()
	bubble.text = "[b]Асистент:[/b]\n" + content
	chat_box.add_child(bubble)


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	var bar: VScrollBar = scroll_container.get_v_scroll_bar()
	scroll_container.scroll_vertical = int(bar.max_value)


func _show_error(message: String) -> void:
	_last_answer.text = "[b]Асистент:[/b]\n[i]" + message + "[/i]"

#endregion


func _on_exit_button_pressed() -> void:
	AssistantManager.end_chat()
	queue_free()
