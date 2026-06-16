## Manages user authentication, including login, registration, and user info synchronization.
##
## This autoload handles communication with authentication API endpoints and stores the active
## session's authorization token and user profile data.
extends Node

## Emitted when a login attempt finishes.
## [param success] Whether the login was successful.
## [param message] Feedback message from the server or auth system.
signal login_attempted(success: bool, message: String)

## Emitted when a registration attempt finishes.
## [param success] Whether the registration was successful.
## [param message] Feedback message from the server or auth system.
signal register_attempted(success: bool, message: String)

## The HTTP header containing the Bearer token for authenticated API requests.
var token_header: Array = [""]

## Cached user info dictionary containing user profile details returned by the server.
var current_user_info: Dictionary = {}


## Sends a login request to the server with the specified credentials.
## Updates the authorization token and user info upon success, synchronizes quests,
## plays the success sound effect, and triggers location transition.
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
		token_header[0] = "Authorization: Bearer " + json_data.get("token", "")
		current_user_info = json_data.get("user", {})
		
		#QuestManager.clear_state()
		await QuestManager.sync_quests()
		
		AudioManager.play_sfx(preload("res://assets/shared/audio/ui/login_successful.wav"), 0.0, "SFX")
		login_attempted.emit(true, "Login successful")
		
		LocationManager.entry_location(current_user_info.get("currentLocation", "error"))
		
		# For backend debug:
		#print(token_header)
	else:
		login_attempted.emit(false, response_body)


## Sends a registration request to the server with the specified credentials.
## Plays a success sound effect and emits [signal register_attempted] on success.
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
	var _response_body: String = response[3].get_string_from_utf8()
	
	if result_code == 200:
		AudioManager.play_sfx(preload("res://assets/shared/audio/ui/registration_successful.wav"), 0.0, "SFX")
		register_attempted.emit(true, "Registration successful")
	else:
		register_attempted.emit(false, "Registration failed")


## Retrieves the latest user info from the server using the stored bearer token
## and updates [member current_user_info].
func update_user_info() -> void:
	var response: Array = await NetworkManager.send_get("/api/Auth/me", token_header)
	if response[1] == 200:
		var response_body: String = response[3].get_string_from_utf8()
		current_user_info = JSON.parse_string(response_body)
	else:
		push_error("Error updating user info. Status: " + response[1])

