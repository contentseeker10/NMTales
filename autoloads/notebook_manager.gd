extends Node

var debug_auth_header: PackedStringArray = [
	'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1laWRlbnRpZmllciI6IjEiLCJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoic3RyaW5nIiwiZXhwIjoxNzgxNTk1MzkzfQ.xzUbZBSf1fdEvbUDN0aUkPQYitEnkizwmpPQBTnLZ_g'
]


func load_pages() -> Array:
	var resp_body: Array = await NetworkManager.send_get("/api/Notebook", debug_auth_header)
	
	if resp_body[1] == 200:
		return JSON.parse_string(resp_body[3].get_string_from_utf8())
	else:
		push_error("Error loading pages data. Status: " + str(resp_body[1]) 
				+ resp_body[3].get_string_from_utf8())
		return []


func create_page(title: String) -> Dictionary:
	var request = NetworkManager.send_post("/api/Notebook", { "title": title }, debug_auth_header)
	
	var response = await request.request_completed
	request.queue_free()
	
	if response[1] == 200:
		return JSON.parse_string(response[3].get_string_from_utf8())
	else:
		push_error("Error creating page. Status: " + str(response[1]) 
				+ response[3].get_string_from_utf8())
		return {}
