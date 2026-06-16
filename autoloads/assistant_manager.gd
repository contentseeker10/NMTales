## Manages dialogue and communication with AI assistants (LLM endpoint).
##
## This autoload handles initiating, restoring, and processing dialogue sessions
## with specialized AI assistant NPCs (e.g., Math, Language, History), interfacing
## with the game's backend API.
extends Node

#region Private vars

## The backend endpoint path for the LLM assistant service.
const _ENDPOINT: String = "/api/LLM"

## Preloaded scene for the assistant chat user interface.
var _assistant_chat_scene: PackedScene = preload("res://ui/menus/dialogue/assistant_chat/assistant_chat.tscn")

## The currently active assistant subject/type (e.g., "Math").
var _active_subject: String = ""

#endregion


#region Starting chat

## Pauses the game, submits telemetry, and initializes the assistant chat UI.
## Also retrieves and restores any past conversation history.
func start_chat(assistant_type: String, npc_name: String) -> void:
	get_tree().paused = true
	_active_subject = assistant_type
	# Report speaking to assistant (e.g. "Math", "Language", "History")
	AchievementsManager.submit_telemetry("AssistantTalked", assistant_type)
	var ui: AssistantChat = _init_ui(npc_name)
	await _restore_conversation(ui)


## Instantiates the assistant chat interface, adds it to the active scene,
## and configures its labels and greeting text.
func _init_ui(npc_name: String) -> AssistantChat:
	var ui: AssistantChat = _assistant_chat_scene.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.assistant_name_label.text = npc_name
	ui.greeting_text.text += npc_name.trim_prefix("Асистент з ")
	return ui


## Fetches the existing conversation history for the active subject from the server
## and populates the chat UI with the loaded messages.
func _restore_conversation(ui: AssistantChat) -> void:
	var url: String = _ENDPOINT + "/" + _active_subject
	var response: Array = await NetworkManager.send_get(url, AuthManager.token_header)
	
	var status: int = response[1]
	var body: String = response[3].get_string_from_utf8()
	
	if status != 200:
		var err := "Error loading past conversation. Status: %s. Info: %s"
		printerr(err % [status, body])
		return

	var data: Dictionary = JSON.parse_string(body)
	ui.load_history(data.get("messages", []))

#endregion


#region Processing prompt/response

## Sends a text prompt to the LLM backend for the active subject.
## Returns a dictionary containing the backend's response message or error details.
func send_player_prompt(prompt: String) -> Dictionary:
	var clean: String = prompt.strip_edges()
	if clean.is_empty():
		return { "error": "Порожнє повідомлення." }

	var url: String = _ENDPOINT + "/" + _active_subject
	var request: HTTPRequest = NetworkManager.send_post(url, { "prompt": clean }, AuthManager.token_header)
	if not request:
		return { "error": "Не вдалося надіслати запит." }

	var response: Array = await request.request_completed
	request.queue_free()

	var status: int = response[1]
	var data: Dictionary = JSON.parse_string(response[3].get_string_from_utf8())

	if status == 200:
		return data

	var error: String = "Не вдалося отримати відповідь."
	error = data.get("error", error)
	return { "error": error }

#endregion


#region Ending chat

## Ends the active chat session, unpauses the game, and clears the active subject state.
func end_chat() -> void:
	get_tree().paused = false
	_active_subject = ""

#endregion
