extends Node

#region Mock mode (while waiting for backend)

var _mock := true
var _mock_data := {
	# WARNING: API is unclear yet
	"answer": "fuck you bitch"
}

#endregion


func send_player_prompt(prompt: String) -> Dictionary:
	if _mock:
		await _simulate_loading(3.0)
		return _mock_data
	
	# TODO: Send POST/GET via NetworkManager once backend is ready
	
	return {}

func _simulate_loading(wait_time: float) -> void:
	var timer := Timer.new()
	timer.wait_time = wait_time
	timer.autostart = true
	timer.one_shot = true
	add_child(timer)
	await timer.timeout
