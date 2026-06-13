extends Node

#region Mock mode (while waiting for backend)

var _mock := true
var _mock_data := {
	# WARNING: API is unclear yet
	"answer": "hey what up"
}

#endregion

#region Private vars

var _assistant_chat_scene: PackedScene = preload("res://ui/menus/dialogue/assistant_chat/assistant_chat.tscn")

#endregion

#region Backend specific

# WARNING: API is unclear yet
var _endpoint_name: String = "LLM"

#endregion


#region Starting chat

func start_chat(assistant_type: String, npc_name: String) -> void:
	get_tree().paused = true
	var data: Dictionary = await _load_data(assistant_type)
	_init_ui(npc_name, data)

func _load_data(assistant_type: String) -> Dictionary:
	var url := "/api/" + _endpoint_name + "/" + assistant_type
	var response := await NetworkManager.send_get(url, AuthManager.token_header)
	
	var status: int = response[1]
	var body: String = response[3].get_string_from_utf8()
	
	if status == 200:
		return JSON.parse_string(body)
	else:
		var error: String = "Error loading chat data. Status: %s. Info: %s"
		printerr(error % [status, body])
		return {  }

func _init_ui(npc_name: String, data: Dictionary) -> void:
	var ui: AssistantChat = _assistant_chat_scene.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.assistant_name_label.text = npc_name
	_load_data_to_ui(ui, data)

func _load_data_to_ui(ui: AssistantChat, data: Dictionary) -> void:
	# TODO: Load saved chat from DB
	pass

#endregion


#region Processing prompt/response

func send_player_prompt(prompt: String) -> Dictionary:
	if _mock:
		await _simulate_loading(2.0)
		return _mock_data
	
	var body := { "prompt": prompt }
	
	# TODO: Send POST/GET via NetworkManager once backend is ready
	
	return {}

func _simulate_loading(wait_time: float) -> void:
	var timer := Timer.new()
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.wait_time = wait_time
	timer.autostart = true
	timer.one_shot = true
	add_child(timer)
	await timer.timeout

#endregion


#region Ending chat

func end_chat() -> void:
	get_tree().paused = false

#endregion
