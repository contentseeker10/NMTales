extends Node

signal quest_updated(quest: Quest)
signal quest_completed(quest: Quest)

var active_quest: Quest


func _ready() -> void:
	EventBus.npc_talked.connect(_on_npc_talked)
	EventBus.location_entered.connect(_on_location_entered)
	EventBus.menu_opened.connect(_on_menu_opened)
	EventBus.quiz_completed.connect(_on_quiz_completed)
	EventBus.mob_killed.connect(_on_mob_killed)


func accept_quest(quest: Quest) -> void:
	active_quest = quest
	quest_updated.emit(active_quest)


func _complete_active_quest() -> void:
	print("Quest is completed: ", active_quest.get("title"))
	quest_completed.emit(active_quest)
	active_quest = null


func _increment_objective_progress() -> void:
	active_quest.current_amount += 1
	quest_updated.emit(active_quest)
	if active_quest.is_completed():
		_complete_active_quest()


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
