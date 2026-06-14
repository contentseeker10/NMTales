extends Node

#region Private vars

const _ENDPOINT: String = "/api/LLM"

var _assistant_chat_scene: PackedScene = preload("res://ui/menus/dialogue/assistant_chat/assistant_chat.tscn")

var _active_subject: String = ""

#endregion


#region Starting chat

func start_chat(assistant_type: String, npc_name: String) -> void:
	get_tree().paused = true
	_active_subject = assistant_type
	# Report speaking to assistant (e.g. "Math", "Language", "History")
	AchievementsManager.submit_telemetry("AssistantTalked", assistant_type)
	var ui: AssistantChat = _init_ui(npc_name)
	await _restore_conversation(ui)


func _init_ui(npc_name: String) -> AssistantChat:
	var ui: AssistantChat = _assistant_chat_scene.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.assistant_name_label.text = npc_name
	ui.greeting_text.text += npc_name.trim_prefix("Асистент з ")
	return ui


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

func end_chat() -> void:
	get_tree().paused = false
	_active_subject = ""

#endregion
