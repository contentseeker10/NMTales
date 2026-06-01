class_name Quest
extends RefCounted

var id: String = ""
var title: String = ""
var giver: String = ""
var description: String = ""
var type: String = ""
var target: String = ""
var current_amount: int = 0
var required_amount: int = 1


func _init(quest_data: Dictionary) -> void:
	_parse_quest_data(quest_data)

func _parse_quest_data(quest_data: Dictionary) -> void:
	id = quest_data.get("id", "error")
	giver = quest_data.get("giver", "error")
	title = quest_data.get("title", "error")
	description = quest_data.get("description", "error")
	var objective: Dictionary = quest_data.get("objective", {})
	type = objective.get("type", "error")
	target = objective.get("target", "error")
	current_amount = objective.get("current_amount", 0)
	required_amount = objective.get("required_amount", 0)


func is_objective_done() -> bool:
	return current_amount >= required_amount
