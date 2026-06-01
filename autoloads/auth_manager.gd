extends Node

signal login_attempted(success: bool, message: String)
signal register_attempted(success: bool, message: String)

var token_header: Array = ["Authorization: Bearer "]
var current_user_info: Dictionary = {}


func login(username: String, password: String) -> void:
	var body: Dictionary = {
		"username": username,
		"password": password
	}
	
	var request: HTTPRequest = NetworkManager.send_post("/api/Auth/login", body)
	if not request:
		login_attempted.emit(false, "Login failed.")
		return
	
	var response: Array = await request.request_completed
	request.queue_free()
	
	var result_code: int = response[1]
	var response_body: String = response[3].get_string_from_utf8()
	
	if result_code == 200:
		var json_data: Variant = JSON.parse_string(response_body)
		token_header[0] += json_data.get("token", "")
		current_user_info = json_data.get("user", {})
		login_attempted.emit(true, "Login successful")
		QuestManager.sync_quests()
	else:
		login_attempted.emit(false, response_body)


func register(username: String, password: String) -> void:
	var body: Dictionary = {
		"username": username,
		"password": password
	}
	
	var request: HTTPRequest = NetworkManager.send_post("/api/Auth/register", body)
	if not request:
		register_attempted.emit(false, "Registration failed")
		return
	
	var response: Array = await request.request_completed
	request.queue_free()
	
	var result_code: int = response[1]
	var response_body: String = response[3].get_string_from_utf8()
	
	if result_code == 200:
		register_attempted.emit(true, "Registration successful")
	else:
		register_attempted.emit(false, "Registration failed")
