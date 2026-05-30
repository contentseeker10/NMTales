extends Node

signal quest_updated(quest_data: Dictionary)
signal quest_completed(quest_data: Dictionary)

var active_quest: Dictionary = {}


func _ready() -> void:
	EventBus.npc_talked.connect(_on_npc_talked)
	EventBus.location_entered.connect(_on_location_entered)
	EventBus.menu_opened.connect(_on_menu_opened)
	EventBus.quiz_completed.connect(_on_quiz_completed)
	EventBus.mob_killed.connect(_on_mob_killed)


func accept_quest(quest: Quest) -> void:
	active_quest = quest.data
	quest_updated.emit(active_quest)


func _complete_active_quest() -> void:
	print("Quest is completed: ", active_quest.get("title"))
	quest_completed.emit(active_quest)
	active_quest = {}


func _increment_objective_progress(objective: Dictionary) -> void:
	objective["current_amount"] += 1
	print("Quest progress was updated: ", \
		objective["current_amount"], "/", objective["required_amount"])
	quest_updated.emit(active_quest)
	if objective["current_amount"] >= objective["required_amount"]:
		_complete_active_quest()


func _process_event(event_type: String, target: String) -> void:
	var objective: Dictionary = active_quest.get("objective", {})
	if objective.get("type") == event_type and objective.get("target") == target:
		_increment_objective_progress(objective)


func _on_npc_talked(npc_id: String) -> void:
	if active_quest.is_empty(): 
		return
	_process_event("talk_npc", npc_id)


func _on_location_entered(location_name: String) -> void:
	if active_quest.is_empty(): 
		return
	_process_event("enter_location", location_name)


func _on_menu_opened(menu_name: String) -> void:
	if active_quest.is_empty(): 
		return
	_process_event("open_menu", menu_name)


func _on_quiz_completed(quiz_id: String) -> void:
	if active_quest.is_empty(): 
		return
	_process_event("complete_quiz", quiz_id)


func _on_mob_killed(mob_id: String) -> void:
	if active_quest.is_empty(): 
		return
	_process_event("kill_mob", mob_id)
