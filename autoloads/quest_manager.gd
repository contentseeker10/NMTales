extends Node

signal quest_updated(quest: Quest)
signal objective_completed(quest: Quest)
signal quest_completed(quest: Quest)

var completed_quest_ids: Array = []
var active_quest: Quest


func _ready() -> void:
	EventBus.dialogue_action_triggered.connect(_on_dialogue_action_triggered)
	EventBus.npc_talked.connect(_on_npc_talked)
	EventBus.location_entered.connect(_on_location_entered)
	EventBus.menu_opened.connect(_on_menu_opened)
	EventBus.quiz_completed.connect(_on_quiz_completed)
	EventBus.mob_killed.connect(_on_mob_killed)


func is_quest_completed(quest_id: String) -> bool:
	return completed_quest_ids.has(quest_id)


func accept_quest(npc_id: String, quest_id: String) -> void:
	if active_quest == null:
		NetworkManager.send_post("/api/Quest/accept/" + npc_id + "/" + quest_id, {}, \
			AuthManager.token_header)
		
		var response: Array = await NetworkManager.send_get("/api/Quest/active", \
			AuthManager.token_header)
		
		if response[1] == 200:
			var response_body: String = response[3].get_string_from_utf8()
			var quest_data: Dictionary = JSON.parse_string(response_body)
			active_quest = Quest.new(quest_data)
			quest_updated.emit(active_quest)
		else:
			push_error("Error accepting quest. Status: ", response[1])


func _on_dialogue_action_triggered(npc: NPC, action: Dictionary) -> void:
	match action.get("type"):
		"accept_quest":
			var quest_id: String = action.get("quest_id")
			accept_quest(npc.npc_id, quest_id)
		"complete_quest":
			_complete_active_quest()


func _complete_active_quest() -> void:
	NetworkManager.send_post("/api/Quest/complete", {}, AuthManager.token_header)
	
	var get_completed_quests: Array = await \
		NetworkManager.send_get("/api/Quest/completed", AuthManager.token_header)
	if get_completed_quests[1] == 200:
		var response_data: String = get_completed_quests[3].get_string_from_utf8()
		completed_quest_ids = JSON.parse_string(response_data)
		
	quest_completed.emit(active_quest)
	active_quest = null


func _increment_objective_progress() -> void:
	active_quest.current_amount += 1
	quest_updated.emit(active_quest)
	if active_quest.is_objective_done():
		objective_completed.emit(active_quest)


func _process_event(event_type: String, target: String) -> void:
	if active_quest.type == event_type and active_quest.target == target:
		_increment_objective_progress()


func _on_npc_talked(npc_id: String) -> void:
	if active_quest == null:
		return
	_process_event("talk_npc", npc_id)


func _on_location_entered(location_name: String) -> void:
	if active_quest == null:
		return
	_process_event("enter_location", location_name)


func _on_menu_opened(menu_name: String) -> void:
	if active_quest == null:
		return
	_process_event("open_menu", menu_name)


func _on_quiz_completed(quiz_id: String) -> void:
	if active_quest == null:
		return
	_process_event("complete_quiz", quiz_id)


func _on_mob_killed(mob_id: String) -> void:
	if active_quest == null:
		return
	_process_event("kill_mob", mob_id)
