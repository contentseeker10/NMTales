extends Node

const BASE_URL: String = "http://localhost:5142"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


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


func send_put(url: String, body: Dictionary, headers: PackedStringArray = []) -> Array:
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	
	var json_body = JSON.stringify(body, "\t")
	var default_headers: PackedStringArray = ["Content-Type: application/json"]
	default_headers.append_array(headers)
	
	var err: Error = http_request.request(BASE_URL + url, default_headers, HTTPClient.METHOD_PUT, json_body)
	if err != OK:
		push_error("HTTP Request PUT failed for " + url)
		http_request.queue_free()
		return [HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray()]
	
	var response: Array = await http_request.request_completed
	http_request.queue_free()
	
	return response


func send_delete(url: String, headers: PackedStringArray = []) -> Array:
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	
	var default_headers: PackedStringArray = ["Content-Type: application/json"]
	default_headers.append_array(headers)
	
	var err: Error = http_request.request(BASE_URL + url, default_headers, HTTPClient.METHOD_DELETE)
	if err != OK:
		push_error("HTTP Request DELETE failed for " + url)
		http_request.queue_free()
		return [HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray()]
	
	var response: Array = await http_request.request_completed
	http_request.queue_free()
	
	return response


func send_get(url: String, headers: PackedStringArray = [], \
			downloading: bool = false, target_path: String = "") -> Array:
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	
	if downloading:
		var parent_dir: String = target_path.get_base_dir()
		
		if not DirAccess.dir_exists_absolute(parent_dir):
			var dir_err: Error = DirAccess.make_dir_recursive_absolute(parent_dir)
			if dir_err != OK:
				push_error("Unable to create directory: " + parent_dir)
				return [HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR, 0, PackedStringArray(), PackedByteArray()]
		
		http_request.download_file = target_path
	
	var err: Error = http_request.request(BASE_URL + url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_error("HTTP Request GET failed for " + url)
		http_request.queue_free()
		return [HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray()]
	
	var response: Array = await http_request.request_completed
	http_request.queue_free()
	
	return response


func download_pack(pack_type: PackManager.PackType, pack_name: String, target_path: String) -> bool:
	var url: String = "/api/" + PackManager.get_pack_type(pack_type) + "/" + pack_name + "/pack"
	
	var response: Array = await send_get(url, AuthManager.token_header, true, target_path)
	var response_code: int = response[1]
	
	if response_code == 200:
		return true
	else:
		DirAccess.remove_absolute(target_path)
		return false


func download_image(image_url: String) -> bool:
	var target_path: String = "user://assets/downloaded" + image_url
	
	var response: Array = await send_get(image_url, AuthManager.token_header, true, target_path)
	var response_code: int = response[1]
	
	if response_code == 200:
		return true
	else:
		DirAccess.remove_absolute(target_path)
		return false
