extends Node

const BASE_URL: String = "http://localhost:5142"

enum PackType {
	LOCATION,
	QUEST
}

func _get_pack_type(pack_type: PackType) -> String:
	match pack_type:
		PackType.LOCATION:
			return "Location"
		PackType.QUEST:
			return "Quest"
	return ""


func send_post(path: String, body: Dictionary, headers: PackedStringArray = []) -> HTTPRequest:
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	
	var json_body = JSON.stringify(body, "\t")
	
	var default_headers: PackedStringArray = ["Content-Type: application/json"]
	default_headers.append_array(headers)
	
	var error: Error = http_request.request(
		BASE_URL + path,
		default_headers,
		HTTPClient.METHOD_POST,
		json_body
	)
	
	if error != OK:
		push_error("HTTP Request POST failed for " + path)
		http_request.queue_free()
		return null
	
	return http_request


func send_get(url: String, headers: PackedStringArray = [], \
			downloading: bool = false, target_path: String = "") -> Array:
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	
	if downloading:
		http_request.download_file = target_path
	
	var err: Error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_error("HTTP Request GET failed for " + url)
		http_request.queue_free()
		return ["null"]
	
	var response: Array = await http_request.request_completed
	http_request.queue_free()
	
	return response


func download_pack(pack_type: PackType, pack_name: String, target_path: String) -> bool:
	var url: String = BASE_URL + "/api/" + _get_pack_type(pack_type) + "/" + pack_name + "/pack"
	
	var token: String = AuthManager.jwt_token
	var headers: PackedStringArray = [
		"Authorization: Bearer " + token
	]
	
	var response: Array = await send_get(url, headers, true, target_path)
	var response_code: int = response[1]
	
	if response_code == 200:
		print("Pack " + pack_name + " was successfully downloaded.")
		return true
	else:
		DirAccess.remove_absolute(target_path)
		print("Error downloading from server. Status: " + str(response[1]))
		return false
