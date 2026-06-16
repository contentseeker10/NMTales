## Manages active and completed quests, syncing them with the server.
##
## This manager listens to various event signals (such as talking to NPCs, entering locations,
## completing quizzes, and defeating mobs) to progress current active quests and handles
## quest acceptance and completion via the network API.
extends Node

## Emitted when the active quest is updated (e.g. accepted, progressed).
signal quest_updated(quest: Quest)
## Emitted when the objective of the active quest is completed.
signal objective_completed(quest: Quest)
## Emitted when the active quest is successfully completed.
signal quest_completed(quest: Quest)

## List of completed quest keys in the format of "npc_id:quest_id".
var completed_quest_ids: Array = []
## The currently active quest, or null if there is no active quest.
var active_quest: Quest


## Initializes the manager and connects signals from [EventBus].
func _ready() -> void:
	EventBus.dialogue_action_triggered.connect(_on_dialogue_action_triggered)
	EventBus.npc_talked.connect(_on_npc_talked)
	EventBus.location_entered.connect(_on_location_entered)
	EventBus.menu_opened.connect(_on_menu_opened)
	EventBus.quiz_completed.connect(_on_quiz_completed)
	EventBus.mob_killed.connect(_on_mob_killed)


# --- buggy at the moment ---
#func clear_state() -> void:
	#completed_quest_ids.clear()
	#active_quest = null;


## Synchronizes active and completed quests with the backend server.
func sync_quests() -> void:
	var active_response: Array = await NetworkManager.send_get("/api/Quest/active", AuthManager.token_header)
	if active_response[1] == 200:
		var response_body: String = active_response[3].get_string_from_utf8()
		var quest_data: Dictionary = JSON.parse_string(response_body)
		active_quest = Quest.new(quest_data)
		quest_updated.emit(active_quest)
	else:
		active_quest = null
	
	var completed_response: Array = await NetworkManager.send_get("/api/Quest/completed", AuthManager.token_header)
	if completed_response[1] == 200:
		var response_body: String = completed_response[3].get_string_from_utf8()
		completed_quest_ids = JSON.parse_string(response_body)


## Maps a sequential or generic quest ID to the actual quest ID based on the npc ID.
func get_actual_quest_id(npc_id: String, sequential_id: String) -> String:
	if npc_id == "npc_guide_main" and sequential_id == "quest_1":
		return "quest_wood"
	elif npc_id == "npc_quest_math":
		return sequential_id.replace("quest_", "quest_math_")
	elif npc_id == "npc_quest_lang":
		return sequential_id.replace("quest_", "quest_lang_")
	elif npc_id == "npc_warning" and sequential_id == "quest_1":
		return "quest_hstr_1"
	return sequential_id


## Returns whether the specified quest has already been completed.
func is_quest_completed(npc_id: String, quest_id: String) -> bool:
	var actual_id = get_actual_quest_id(npc_id, quest_id)
	var composite_key: String = npc_id + ":" + actual_id
	return completed_quest_ids.has(composite_key) or completed_quest_ids.has(npc_id + ":" + quest_id)


## Accepts a quest by sending a request to the server and updating the active quest.
func accept_quest(npc_id: String, quest_id: String) -> void:
	if active_quest == null:
		var post_accept: HTTPRequest = NetworkManager.send_post("/api/Quest/accept/" + npc_id + "/" + quest_id, {}, \
			AuthManager.token_header)
		var _post_response: Array = await post_accept.request_completed
		
		var response: Array = await NetworkManager.send_get("/api/Quest/active", \
			AuthManager.token_header)
		
		if response[1] == 200:
			var response_body: String = response[3].get_string_from_utf8()
			var quest_data: Dictionary = JSON.parse_string(response_body)
			active_quest = Quest.new(quest_data)
			quest_updated.emit(active_quest)
			AudioManager.play_sfx(preload("res://assets/shared/audio/ui/quest_accepted.wav"), 0.0, "SFX")
		else:
			push_error("Error accepting quest. Status: ", response[1])


## Internal callback when a dialogue action is triggered. Handles quest acceptance/completion.
func _on_dialogue_action_triggered(npc: NPC, action: Dictionary) -> void:
	match action.get("type"):
		"accept_quest":
			var quest_id: String = action.get("quest_id")
			accept_quest(npc.npc_id, quest_id)
		"complete_quest":
			_complete_active_quest()
		"complete_quiz":
			var quiz_id: String = action.get("quiz_id")
			EventBus.quiz_completed.emit(quiz_id)


## Completes the active quest and updates completed quests from the server.
func _complete_active_quest() -> void:
	var request: HTTPRequest = NetworkManager.send_post("/api/Quest/complete", {}, AuthManager.token_header)
	if request:
		var _response: Array = await request.request_completed
		request.queue_free()
		var get_completed_quests: Array = await \
		NetworkManager.send_get("/api/Quest/completed", AuthManager.token_header)
		if get_completed_quests[1] == 200:
			var response_data: String = get_completed_quests[3].get_string_from_utf8()
			completed_quest_ids = JSON.parse_string(response_data)
	AudioManager.play_sfx(preload("res://assets/shared/audio/ui/quest_completed.wav"), 0.0, "SFX")
	quest_completed.emit(active_quest)
	active_quest = null


## Sends a progress update to the server for a specific quest objective event.
func _process_event(event_type: String, target: String) -> void:
	if active_quest == null:
		return
	
	if active_quest.type == event_type and active_quest.target == target:
		var body: Dictionary = {
			"eventType": event_type,
			"target": target
		}
		
		var request: HTTPRequest = NetworkManager.send_post("/api/Quest/progress", body, AuthManager.token_header)
		if request:
			var response: Array = await request.request_completed
			request.queue_free()
			
			if response[1] == 200:
				var response_body: Dictionary = JSON.parse_string(response[3].get_string_from_utf8())
				var server_current_amount = response_body.get("currentAmount", 0)
				
				active_quest.current_amount = server_current_amount
				quest_updated.emit(active_quest)
				
				if active_quest.is_objective_done():
					objective_completed.emit(active_quest)


## Callback triggered when the player talks to an NPC.
func _on_npc_talked(npc_id: String) -> void:
	if active_quest == null:
		return
	_process_event("talk_npc", npc_id)


## Callback triggered when the player enters a location.
func _on_location_entered(location_name: String) -> void:
	if active_quest == null:
		return
	_process_event("enter_location", location_name)


## Callback triggered when a menu is opened.
func _on_menu_opened(menu_name: String) -> void:
	if active_quest == null:
		return
	_process_event("open_menu", menu_name)


## Callback triggered when a quiz is completed.
func _on_quiz_completed(quiz_id: String) -> void:
	if active_quest == null:
		return
	_process_event("complete_quiz", quiz_id)


## Callback triggered when a mob is killed.
func _on_mob_killed(mob_id: String) -> void:
	if active_quest == null:
		return
	_process_event("kill_mob", mob_id)
