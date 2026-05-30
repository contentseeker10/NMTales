extends Node

signal quest_updated(quest: Quest)
signal objective_completed(quest: Quest)
signal quest_completed(quest: Quest)

var completed_quests: Array[Quest] = []
var active_quest: Quest


func _ready() -> void:
	EventBus.dialogue_action_triggered.connect(_on_dialogue_action_triggered)
	EventBus.npc_talked.connect(_on_npc_talked)
	EventBus.location_entered.connect(_on_location_entered)
	EventBus.menu_opened.connect(_on_menu_opened)
	EventBus.quiz_completed.connect(_on_quiz_completed)
	EventBus.mob_killed.connect(_on_mob_killed)


func accept_quest(quest: Quest) -> void:
	if active_quest == null:
		active_quest = quest
		quest_updated.emit(active_quest)


func _complete_active_quest() -> void:
	quest_completed.emit(active_quest)
	completed_quests.append(active_quest)
	active_quest.completed = true
	active_quest = null


func _increment_objective_progress() -> void:
	active_quest.current_amount += 1
	quest_updated.emit(active_quest)
	if active_quest.is_objective_done():
		objective_completed.emit(active_quest)


func _process_event(event_type: String, target: String) -> void:
	if active_quest.type == event_type and active_quest.target == target:
		_increment_objective_progress()


func _on_dialogue_action_triggered(npc: NPC, action: Dictionary) -> void:
	match action.get("type"):
		"accept_quest":
			var quest_id: String = action.get("quest_id")
			accept_quest(npc.quests.get(int(quest_id.trim_prefix("quest_")) - 1))
		"complete_quest":
			_complete_active_quest()


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
