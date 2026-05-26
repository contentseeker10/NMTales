extends Node


signal login_status(success: bool, message: String)
signal register_status(success: bool, message: String)

var jwt_token: String = ""
var current_user_info: Dictionary = {}


func login(username: String, password: String) -> void:
	var body: Dictionary = {
		"username": username,
		"password": password
	}
	
	var request: HTTPRequest = NetworkManager.send_post("/api/Auth/login", body)
	if not request:
		login_status.emit(false, "Login failed.")
		return
	
	var response: Array = await request.request_completed
	request.queue_free()
	
	var result_code: int = response[1]
	var response_body: String = response[3].get_string_from_utf8()
	
	if result_code == 200:
		var json_data: Variant = JSON.parse_string(response_body)
		jwt_token = json_data.get("token", "")
		current_user_info = json_data.get("user", {})
		login_status.emit(true, "Login successful")
	else:
		login_status.emit(false, response_body)


func register(username: String, password: String) -> void:
	var body: Dictionary = {
		"username": username,
		"password": password
	}
	
	var request: HTTPRequest = NetworkManager.send_post("/api/Auth/register", body)
	if not request:
		register_status.emit(false, "Registration failed")
		return
	
	var response: Array = await request.request_completed
	request.queue_free()
	
	var result_code: int = response[1]
	var response_body: String = response[3].get_string_from_utf8()
	
	if result_code == 200:
		register_status.emit(true, "Registration successful")
	else:
		register_status.emit(false, "Registration failed")
