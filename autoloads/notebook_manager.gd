extends Node

# TODO: Change to AuthManager.token_header
var _auth_header: PackedStringArray = [
	'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1laWRlbnRpZmllciI6IjEiLCJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoic3RyaW5nIiwiZXhwIjoxNzgxNTk2Mzc1fQ.ZhIJWhU1FobnIHdVe8EBXBqD6Mgd1PouLKgQYW1Iygs'
]


func load_pages() -> Array:
	var resp_body: Array = await NetworkManager.send_get("/api/Notebook", _auth_header)
	
	if resp_body[1] == 200:
		return JSON.parse_string(resp_body[3].get_string_from_utf8())
	else:
		push_error("Error loading pages data. Status: " + str(resp_body[1]) 
				+ resp_body[3].get_string_from_utf8())
		return []


func create_page(title: String) -> Dictionary:
	var request = NetworkManager.send_post("/api/Notebook", { "title": title }, _auth_header)
	
	var response = await request.request_completed
	request.queue_free()
	
	if response[1] == 200:
		return JSON.parse_string(response[3].get_string_from_utf8())
	else:
		push_error("Error creating page. Status: " + str(response[1]) 
				+ response[3].get_string_from_utf8())
		return {}


func update_page(id: int, title: String, content: String) -> void:
	var body: Dictionary = {
		"title": title,
		"content": content
	}
	var resp_body: Array = await NetworkManager.send_put("/api/Notebook/" + str(id), body, _auth_header)
	if resp_body[1] != 204:
		push_error("Error updating page. Status: " + str(resp_body[1]) + resp_body[3].get_string_from_utf8())


func delete_page(id: int) -> void:
	var resp_body: Array = await NetworkManager.send_delete("/api/Notebook/" + str(id), _auth_header)
	if resp_body[1] != 200 or resp_body[1] != 204:
		push_error("Error deleting page. Status: " + str(resp_body[1]) + resp_body[3].get_string_from_utf8())
