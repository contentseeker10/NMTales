extends Node


func load_pages() -> Array:
	var resp_body: Array = await NetworkManager.send_get("/api/Notebook", AuthManager.token_header)
	
	if resp_body[1] == 200:
		return JSON.parse_string(resp_body[3].get_string_from_utf8())
	else:
		push_error("Error loading pages data. Status: " + str(resp_body[1]) 
				+ resp_body[3].get_string_from_utf8())
		return []


func create_page(title: String) -> Dictionary:
	var request = NetworkManager.send_post("/api/Notebook", { "title": title }, AuthManager.token_header)
	
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
	var resp_body: Array = await NetworkManager.send_put("/api/Notebook/" + str(id), body, AuthManager.token_header)
	if resp_body[1] != 200 and resp_body[1] != 204:
		push_error("Error updating page. Status: " + str(resp_body[1]) + resp_body[3].get_string_from_utf8())


func delete_page(id: int) -> void:
	var resp_body: Array = await NetworkManager.send_delete("/api/Notebook/" + str(id), AuthManager.token_header)
	if resp_body[1] != 200 and resp_body[1] != 204:
		push_error("Error deleting page. Status: " + str(resp_body[1]) + resp_body[3].get_string_from_utf8())
