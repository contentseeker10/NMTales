extends Node
## Drives the AI tutor chat UI. All AI work — the Gemini call, the subject persona and the
## conversation history — lives on the backend (`api/LLM/{subject}`). This autoload only opens
## the chat, relays the player's prompt, and hands the answer back to the UI.
##
## `assistant_type` matches the NPC export enum on `npc.gd`: "Math", "Language", "History".

#region Private vars

const _ENDPOINT: String = "/api/LLM"

var _assistant_chat_scene: PackedScene = preload("res://ui/menus/dialogue/assistant_chat/assistant_chat.tscn")

var _active_subject: String = ""

#endregion


#region Starting chat

func start_chat(assistant_type: String, npc_name: String) -> void:
	get_tree().paused = true
	_active_subject = assistant_type
	var ui: AssistantChat = _init_ui(npc_name)
	await _restore_conversation(ui)


func _init_ui(npc_name: String) -> AssistantChat:
	var ui: AssistantChat = _assistant_chat_scene.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.assistant_name_label.text = npc_name
	return ui


## Loads any saved conversation for this subject so the chat reopens where it left off.
func _restore_conversation(ui: AssistantChat) -> void:
	var url: String = _ENDPOINT + "/" + _active_subject
	var response: Array = await NetworkManager.send_get(url, AuthManager.token_header)

	if response[1] != 200:
		return

	var data: Variant = JSON.parse_string(response[3].get_string_from_utf8())
	if typeof(data) == TYPE_DICTIONARY:
		ui.load_history(data.get("messages", []))

#endregion


#region Processing prompt/response

## Sends the player's prompt to the backend tutor.
## Success: { "answer": String }. Failure: { "error": String }.
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
	var data: Variant = JSON.parse_string(response[3].get_string_from_utf8())

	if status == 200 and typeof(data) == TYPE_DICTIONARY and data.has("answer"):
		return { "answer": data["answer"] }

	var error: String = "Не вдалося отримати відповідь."
	if typeof(data) == TYPE_DICTIONARY:
		error = data.get("error", error)
	return { "error": error }

#endregion


#region Ending chat

func end_chat() -> void:
	get_tree().paused = false
	_active_subject = ""

#endregion
