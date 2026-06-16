## A chat interface for communicating with an AI assistant in-game.
## 
## Handles sending user prompts, displaying dialogue history,
## showing assistant response states (like loading/thinking indicator),
## and scrolling the chat box container.
class_name AssistantChat
extends CanvasLayer

#region Private vars

## PackedScene for rendering the player's text bubbles in the chat.
var _player_text_scene: PackedScene = preload("res://ui/menus/dialogue/answers/player_text.tscn")
## PackedScene for rendering the assistant's (NPC) text bubbles in the chat.
var _npc_text_scene: PackedScene = preload("res://ui/menus/dialogue/answers/npc_text.tscn")

## Reference to the last sent player prompt label.
var _last_prompt: RichTextLabel
## Reference to the last assistant answer label (used to update status/content).
var _last_answer: RichTextLabel

## Tracks whether the interface is currently waiting for an assistant response.
var _is_waiting: bool = false

#endregion

#region Node imports

## The label displaying the name of the assistant.
@onready var assistant_name_label: Label = $VBoxContainer/AssistantNameLabel
## The scroll container that wraps the chat contents.
@onready var scroll_container: ScrollContainer = $VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer
## The initial greeting message label.
@onready var greeting_text: RichTextLabel = $VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/ChatBox/GreetingText
## The text entry field where the player types their prompts.
@onready var line_edit: LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit
## The container holding the messages in chronological order.
@onready var chat_box: VBoxContainer = $VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/ChatBox
## The button used to send the message.
@onready var send_button: Button = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/SendButton

#endregion


## Called when the node enters the scene tree. Connects UI events.
func _ready() -> void:
	line_edit.text_submitted.connect(_on_line_edit_text_submitted)


## Loads a list of previous chat messages into the chat history.
## [param messages] An array of dictionaries, where each dictionary represents a message with 'role' and 'content' keys.
func load_history(messages: Array) -> void:
	for message: Dictionary in messages:
		if message.get("role", "") == "user":
			_add_prompt(message.get("content", ""))
		else:
			_append_assistant_text(message.get("content", ""))
	await _scroll_to_bottom()


#region Chatting handler

## Callback for when the user submits text via LineEdit.
## [param _new_text] The text that was submitted.
func _on_line_edit_text_submitted(_new_text: String) -> void:
	_on_send_button_pressed()


## Callback for when the send button is pressed. Initiates sending process.
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


## Enables or disables the chat input controls.
## [param enabled] True to allow typing and sending; false to lock inputs during response generation.
func _set_input_enabled(enabled: bool) -> void:
	_is_waiting = not enabled
	line_edit.editable = enabled
	send_button.disabled = not enabled
	if enabled:
		line_edit.grab_focus()


## Adds a player prompt bubble to the chat container.
## [param prompt] The message text typed by the player.
func _add_prompt(prompt: String) -> void:
	var player_prompt: RichTextLabel = _player_text_scene.instantiate()
	player_prompt.text = "[b]" + AuthManager.current_user_info.get("username", "error") + ":[/b]\n" \
					+ prompt
	chat_box.add_child(player_prompt)
	_last_prompt = player_prompt


## Adds a placeholder assistant response bubble with a loading animation.
func _add_answer() -> void:
	var assistant_answer: RichTextLabel = _npc_text_scene.instantiate()
	assistant_answer.text = "[b]Асистент:[/b]\n" + \
							"[shake rate=20.0 level=5 connected=1]...[/shake]"
	chat_box.add_child(assistant_answer)
	_last_answer = assistant_answer


## Updates the last assistant answer bubble with the received response content.
## [param data] A dictionary containing the 'answer' key with the text content.
func _load_answer(data: Dictionary) -> void:
	_last_answer.text = "[b]Асистент:[/b]\n" + data.get("answer", "error")


## Appends a completed assistant message bubble (used when loading history).
## [param content] The message text from the assistant.
func _append_assistant_text(content: String) -> void:
	var bubble: RichTextLabel = _npc_text_scene.instantiate()
	bubble.text = "[b]Асистент:[/b]\n" + content
	chat_box.add_child(bubble)


## Scrolls the chat view to the bottom so the latest message is visible.
func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	var bar: VScrollBar = scroll_container.get_v_scroll_bar()
	scroll_container.scroll_vertical = int(bar.max_value)


## Displays an error message in place of the last assistant answer.
## [param message] The error message text to display.
func _show_error(message: String) -> void:
	_last_answer.text = "[b]Асистент:[/b]\n[i]" + message + "[/i]"

#endregion


## Callback for when the exit/close button is pressed. Cleans up the chat session.
func _on_exit_button_pressed() -> void:
	AssistantManager.end_chat()
	queue_free()
