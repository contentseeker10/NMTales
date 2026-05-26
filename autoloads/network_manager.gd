extends Node


const BASE_URL: String = "http://localhost:5142"


func send_post(path: String, body: Dictionary, headers: Array[String] = []) -> HTTPRequest:
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	
	var json_body = JSON.stringify(body, "\t")
	
	var default_headers: Array = ["Content-Type: application/json"]
	default_headers.append(headers)
	
	var error: Error = http_request.request(
		BASE_URL + path,
		default_headers,
		HTTPClient.METHOD_POST,
		json_body
	)
	
	if error != OK:
		push_error("HTTP Request initialization error to " + path)
		http_request.queue_free()
		return null
	
	return http_request
