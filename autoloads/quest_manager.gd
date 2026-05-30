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


func accept_quest(quest_data: Dictionary) -> void:
	active_quest = quest_data
	quest_updated.emit(active_quest)


func _on_npc_talked(npc_id: String) -> void:
	pass


func _on_location_entered(location_name: String) -> void:
	pass


func _on_menu_opened(menu_name: String) -> void:
	pass


func _on_quiz_completed(quiz_id: String) -> void:
	pass


func _on_mob_killed(mob_id: String) -> void:
	pass
